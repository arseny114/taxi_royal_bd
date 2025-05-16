-- Первый триггер.
-- При добавлении нового отказа водителя проверяется статус заказа и 
-- выполняющий его водитель. Если на заказ был добавлен другой водитель 
-- или если заказ находится не в статусе “водитель найден”, то добавление 
-- отказа невозможно. Если заказ находится в статусе “водитель найден” 
-- и водитель тот же, что и в отказе, то статус заказа меняется на 
-- “только создан”, а водитель из заказа удаляется (в моем случае туда записывается NULL). 
-- При отказе выводить сообщение об ошибке.
CREATE OR REPLACE FUNCTION driver_reject_handler()
RETURNS TRIGGER AS $$
DECLARE
  current_driver_id_from_taxi_order INT;
  current_order_status_id_from_taxi_order INT;
  driver_has_been_found_id INT;
  just_created_id INT;

BEGIN
  -- Получаем водителя, который в данный момент записан как выполняющий заказ
  -- И статус заказа, который в данный момент имеет заказ
  SELECT driver_id, taxi_order_status_id
  INTO current_driver_id_from_taxi_order, current_order_status_id_from_taxi_order
  FROM taxi_order
  WHERE taxi_order_id = NEW.taxi_order_id;

  -- Получаем id всех нужных нам статусов заказов
  SELECT taxi_order_status_id
  INTO driver_has_been_found_id 
  FROM taxi_order_status
  WHERE status_name = 'driver_has_been_found';

  SELECT taxi_order_status_id
  INTO just_created_id 
  FROM taxi_order_status
  WHERE status_name = 'just_created';

  -- Проверяем, что водитель в отказе и в заказе это не разные люди
  IF NEW.driver_id != current_driver_id_from_taxi_order THEN
    RAISE EXCEPTION 'Отказывающийся и выполняющий заказ водитель должен быть одним и тем же человеком';
  END IF;

  -- Проверяем, что заказ находится в статусе водитель найден
  IF current_order_status_id_from_taxi_order = driver_has_been_found_id THEN
    RAISE EXCEPTION 'Заказ не должен находится в статусе driver_has_been_found';
  END IF;

  -- В случае, если проверки выше пройдены проверяем, что у заказа  нужный статус
  UPDATE taxi_order 
  SET 
    taxi_order_status_id = just_created_id,
    driver_id = NULL
  WHERE taxi_order_id = NEW.taxi_order_id;

  RETURN NEW;

END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER driver_reject_trigger
BEFORE INSERT ON driver_rejection
FOR EACH ROW EXECUTE FUNCTION driver_reject_handler();

-- Второй триггер.
-- При оформлении нового договора о сотрудничестве между таксопарком и водителем проверяется, что:
-- 1) у водителя нет действующего договора;
-- 2) машина не используется в действующих договорах.
-- Если водитель или машина занята, то договор не оформляется. Если договор заключить можно, 
-- то проверяется срок договора, если он больше 11 месяцев, то автоматически исправляется на 
-- договор с длительностью 11 месяцев.
CREATE OR REPLACE FUNCTION contract_handler()
RETURNS TRIGGER AS $$
DECLARE
  num_cur_contracts_driver INT;
  num_cur_contracts_car INT;

BEGIN
  -- Считаем в скольки действующих договорах водитель есть на данный момент
  SELECT COUNT(*)
  INTO num_cur_contracts_driver
  FROM (SELECT * FROM contract
  WHERE now() >= start_date AND now() <= end_date 
  AND taxi_user_id = NEW.taxi_user_id);

  -- Считаем в скольки действующих договорах машина есть на данный момент
  SELECT COUNT(*)
  INTO num_cur_contracts_car
  FROM (SELECT * FROM contract
  WHERE now() >= start_date AND now() <= end_date
  AND car_registration_id = NEW.car_registration_id);
  
  -- Проверяем, что у водителя нет текущего договора
  IF num_cur_contracts_driver > 0 THEN 
    RAISE EXCEPTION 'У водителя уже есть действующий договор';
  END IF;

  -- Проверяем, что машина не используется в других договорах
  IF num_cur_contracts_car > 0 THEN 
    RAISE EXCEPTION 'Машина уже используется в другом договоре';
  END IF;

  -- Проверяем, что договор не больше 11 месяцев
  IF date_part('months', age(NEW.start_date, NEW.end_date))::INT > 11 THEN
    NEW.end_date := NEW.start_date + INTERVAL '11 months';
  END IF;
    
  RETURN NEW;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER contract_trigger
BEFORE INSERT ON contract
FOR EACH ROW EXECUTE FUNCTION contract_handler();































