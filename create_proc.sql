-- Процедура 1. Регистрация нового договора с водителем
-- Процедура предназначена для заключения нового договора 
-- с водителем. Процедура принимает идентификаторы водителя, 
-- машины и таксопарка и, если они существуют и нет действующих 
-- договоров у водителя, то создается договор между водителем 
-- и таксопарком. Если договор не может создан, то выдается 
-- сообщение об ошибке. Длительность договора равна 6 месяце 
-- + 7 дней * число истекших договоров водителя.
CREATE OR REPLACE PROCEDURE add_new_contract(
  input_driver_id INT,
  input_car_id INT,
  input_pool_id INT,
  input_admin_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  driver_role_id INT;
  admin_role_id INT;
  new_contract_id INT;
  new_contract_start_date TIMESTAMPTZ;
  new_contract_end_date TIMESTAMPTZ;
  num_expired_contracts INT;

BEGIN
  -- Получаем id роли водителя и админа
  driver_role_id := (SELECT role_id FROM role WHERE role_name = 'driver');
  admin_role_id := (SELECT role_id FROM role WHERE role_name = 'administrator');

  -- Проверяем, что водитель существует
  IF (SELECT COUNT(*) FROM taxi_user WHERE taxi_user_id = input_driver_id AND role_id = driver_role_id) != 1 THEN
    RAISE EXCEPTION 'Такого водителя не существует';
  END IF;

  -- Проверять, что у водителя нет действующих договоров будет триггер contract_trigger

  -- Проверяем, что машина существует
  IF (SELECT COUNT(*) FROM car WHERE car_registration_id = input_car_id) != 1 THEN
    RAISE EXCEPTION 'Такой машины не существует';
  END IF;

  -- Проверяем, что таксопарк существует
  IF (SELECT COUNT(*) FROM taxi_pool WHERE taxi_pool_id = input_pool_id) != 1 THEN
    RAISE EXCEPTION 'Такого таксопарка не существует';
  END IF;

  -- Проверяем, что админ, который регистрирует договор, существует
  IF (SELECT COUNT(*) FROM taxi_user WHERE taxi_user_id = input_admin_id AND role_id = admin_role_id) != 1 THEN
    RAISE EXCEPTION 'Такого администратора не существует';
  END IF;

  -- Расчитываем количество истекщих договоров
  num_expired_contracts := (SELECT COUNT(*) 
                            FROM contract 
                            WHERE taxi_user_id = input_driver_id 
                            AND end_date < NOW())::INT;

  -- Расчитываем дату начала и конца договора
  new_contract_start_date := NOW()::TIMESTAMPTZ;
  new_contract_end_date := (NOW() + INTERVAL '6 months' + (INTERVAL '7 days' * num_expired_contracts))::TIMESTAMPTZ;

  -- Если все нормально добавляем новый контракт
  INSERT INTO contract (car_registration_id, admin_id, taxi_user_id, taxi_pool_id, start_date, end_date)
  VALUES (input_car_id, input_admin_id, input_driver_id, input_pool_id, new_contract_start_date, new_contract_end_date)
  RETURNING contract_id INTO new_contract_id;

  RAISE NOTICE 'Заключен новый контракт с ID: %', new_contract_id;

END;
$$;

-- Процедура 2. Окончание поездки
-- Процедура предназначена для завершения поездки и расчета ее стоимости. 
-- Процедура принимает id заказа в статусе “поездка начата” и меняет статус 
-- на “поездка закончена”. Если поездка в другом статусе, то сообщается об 
-- ошибке. Стоимость поездки рассчитывается исходя из длительности поездки 
-- и тарифа.
CREATE OR REPLACE PROCEDURE completing_the_trip(
  input_taxi_order_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  trip_started_status_id INT;
  trip_ended_status_id INT;
  cost_trip FLOAT;
  cur_trip_tariff FLOAT;
  cur_trip_start_date TIMESTAMPTZ;
  cur_trip_end_date TIMESTAMPTZ;

BEGIN
  -- Проверяем, что такой заказ существует
  IF (SELECT COUNT(*) FROM taxi_order WHERE taxi_order_id = input_taxi_order_id) != 1 THEN
    RAISE EXCEPTION 'Такого заказа не существует';
  END IF;

  -- Получаем id используемых в процедуре статусов
  trip_started_status_id := (SELECT taxi_order_status_id FROM taxi_order_status WHERE status_name = 'ride_started');
  trip_ended_status_id := (SELECT taxi_order_status_id FROM taxi_order_status WHERE status_name = 'ride_completed');

  -- Проверяем, что у заказа правильынй статус
  IF (SELECT taxi_order_status_id FROM taxi_order WHERE taxi_order_id = input_taxi_order_id) != trip_started_status_id THEN
    RAISE EXCEPTION 'Заказ не находится в статусе поездка начата';
  END IF;

  -- Ставим поездке статус, что она закончена
  UPDATE taxi_order
  SET taxi_order_status_id = trip_ended_status_id
  WHERE taxi_order_id = input_taxi_order_id;

  -- Узнаем время начала поездки
  cur_trip_start_date := 
  (
    SELECT start_date
    FROM taxi_order
    WHERE taxi_order_id = input_taxi_order_id
  );

  -- Время конца поездки
  cur_trip_end_date := now();

  -- Записываем время конца поездки в таблицу 
  UPDATE taxi_order
  SET end_date = cur_trip_end_date
  WHERE taxi_order_id = input_taxi_order_id;

  -- Узнаем id тарифа поездки
  cur_trip_tariff := (
    SELECT trip_tariff 
    FROM trip_type 
    WHERE trip_type_id = 
    (
      SELECT trip_type_id 
      FROM taxi_order 
      WHERE taxi_order_id = input_taxi_order_id
    )
  );

  -- Вычисляем стоимость поездки
  cost_trip := cur_trip_tariff * date_part('minute', age(cur_trip_start_date, cur_trip_end_date))::FLOAT;

  -- Записываем стоимость поездки в задолженность клиента
  UPDATE taxi_user
  SET 
    debit = debit + cost_trip
    WHERE taxi_user_id = 
    (
      SELECT client_id 
      FROM taxi_order 
      WHERE taxi_order_id = input_taxi_order_id
  );

END;
$$;
