-- Заполнение информацией таблицы Города / E1
INSERT INTO city (city_name) VALUES 
('New York'),
('London'),
('Tokyo'),
('Paris'),
('Berlin'),
('Sydney'),
('Dubai'),
('Toronto'),
('Singapore'),
('Rome');

-- Заполнение информацией таблицы Роль пользователя / E5
INSERT INTO role (role_name) VALUES 
('client'),
('driver'),
('administrator'),
('dispatcher'),
('owner');

-- Заполнение информацией таблицы Пользователь системы / E4
INSERT INTO taxi_user (role_id, first_name, last_name, phone_number, inn, debit, registration_date) VALUES
-- Администраторы (role_id = 3)
(3, 'John', 'Smith', '+12345678901', NULL, 0, '2022-01-09 23:59:59+00'),
(3, 'Emily', 'Johnson', '+19876543210', NULL, 0, '2022-02-11 23:59:59+00'),

-- Диспетчеры (role_id = 4)
(4, 'Michael', 'Williams', '+15551234567', NULL, 0, '2022-03-18 23:59:59+00'),
(4, 'Sarah', 'Brown', '+15559876543', NULL, 0, '2022-04-17 23:59:59+00'),

-- Водители (role_id = 2)
(2, 'David', 'Miller', '+17771234567', '1234567890', 3000.50, '2022-05-09 23:59:59+00'),
(2, 'Jessica', 'Davis', '+17779876543', '9876543210', 0, '2022-06-07 23:59:59+00'),

-- Клиенты (role_id = 1)
(1, 'Robert', 'Wilson', '+18881234567', NULL, 0, '2022-07-11 23:59:59+00'),
(1, 'Jennifer', 'Taylor', '+18889876543', NULL, 0, '2022-08-20 23:59:59+00'),
(1, 'Thomas', 'Anderson', '+19991234567', NULL, 0, '2022-09-19 23:59:59+00'),
(1, 'Lisa', 'Martinez', '+19999876543', NULL, 2250, '2021-10-24 23:59:59+00'),

-- Владельцы таксопарков (role_id = 5)
(5, 'James', 'Wilson', '+19001234567', '1122334455', 0, '2022-11-04 23:59:59+00'),
(5, 'Sophia', 'Garcia', '+19009876543', '5566778899', 0, '2022-01-15 23:59:59+00'),

-- Еще три водителя для статистики по отказам
(2, 'David', 'Kloe', '+18889876543', '1276543210', 0, '2022-06-07 23:59:59+00'),
(2, 'Bob', 'Lorian', '+19999876543', '1576543210', 0, '2022-05-08 23:59:59+00'),
(2, 'Ivan', 'Ibragimov', '+10009876543', '2476543210', 0, '2022-04-09 23:59:59+00');

-- Заполнение информацией таблицы Таксопарки / E2
INSERT INTO taxi_pool (city_id, admin_id, owner_id, address, description) VALUES
-- Таксопарки в Нью-Йорке (city_id = 1)
(1, 1, 11, '123 Broadway, Manhattan', 'Premium taxi services in NYC'),
(1, 2, 12, '456 5th Avenue, Brooklyn', '24/7 taxi dispatch center'),

-- Таксопарки в Лондоне (city_id = 2)
(2, 1, 11, '78 Oxford Street', 'Luxury car fleet with professional drivers'),
(2, 2, 12, '22 Baker Street', 'Eco-friendly electric vehicles'),

-- Таксопарки в Токио (city_id = 3)
(3, 1, 11, '1-2 Shibuya Crossing', 'High-tech dispatch system'),
(3, 2, 12, '3 Ginza District', 'VIP corporate transportation'),

-- Таксопарки в Париже (city_id = 4)
(4, 1, 11, '55 Champs-Élysées', 'Multilingual drivers'),
(4, 2, 12, '18 Montmartre', 'Pet-friendly vehicles'),

-- Таксопарки в Берлине (city_id = 5)
(5, 1, 11, '101 Friedrichstraße', 'Wheelchair accessible fleet'),
(5, 2, 12, '25 Alexanderplatz', 'Budget taxi options');

-- Заполнение информацией таблицы Тип поездки / E3
INSERT INTO trip_type (trip_name, trip_description, trip_tariff, trip_min_price, profit_multiplier) VALUES
('Economy', 'Budget option with standard vehicles', 20, 5.00, 0.7),
('Comfort', 'Premium vehicles with extra legroom', 35, 10.00, 0.75),
('Business', 'Luxury vehicles with professional drivers', 50, 20.00, 0.8);

-- Заполнение информацией таблицы Тип автомобиля / E12
INSERT INTO type_car (type_car_name) VALUES
('Sedan'),
('SUV'),
('Minivan'),
('Luxury'),
('Electric');

-- Заполнение информацией таблицы Автомобиль / E6
INSERT INTO car (type_car_id, owner_id, car_brand_name, rental_price, maintenance_price) VALUES
-- Sedans (type_car_id = 1)
(1, 1, 'Toyota Camry', 45.00, 15.00),
(1, 2, 'Honda Accord', 42.00, 14.00),
(1, 3, 'Hyundai Sonata', 40.00, 13.00),
(1, 4, 'Kia K5', 41.00, 14.00),

-- SUVs (type_car_id = 2)
(2, 5, 'Ford Explorer', 65.00, 22.00),
(2, 6, 'Toyota RAV4', 60.00, 20.00),
(2, 7, 'Honda CR-V', 58.00, 19.00),
(2, 8, 'Nissan Rogue', 55.00, 18.00),

-- Minivans (type_car_id = 3)
(3, 9, 'Chrysler Pacifica', 70.00, 25.00),
(3, 10, 'Honda Odyssey', 68.00, 24.00),

-- Luxury (type_car_id = 4)
(4, 1, 'Mercedes E-Class', 120.00, 40.00),
(4, 3, 'BMW 5 Series', 115.00, 38.00),
(4, 5, 'Audi A6', 110.00, 36.00),

-- Electric (type_car_id = 5)
(5, 2, 'Tesla Model 3', 90.00, 30.00),
(5, 4, 'Nissan Leaf', 75.00, 28.00);

-- Заполнение информацией таблицы Договор о сотрудничестве / E7
INSERT INTO contract (
  car_registration_id,
  admin_id,
  taxi_user_id,
  taxi_pool_id,
  start_date,
  end_date
) VALUES
-- Contracts for driver David Miller (taxi_user_id = 5)
(1, 1, 5, 1, '2023-01-15 00:00:00+00', '2024-01-14 23:59:59+00'),  -- Toyota Camry in NYC
-- (5, 2, 5, 5, '2023-06-01 00:00:00+00', '2024-05-31 23:59:59+00'),  -- Ford Explorer in Tokyo

-- Contracts for driver Jessica Davis (taxi_user_id = 6)
(2, 1, 6, 2, '2023-02-20 00:00:00+00', '2024-02-19 23:59:59+00');  -- Honda Accord in London
-- (15, 2, 6, 8, '2023-07-15 00:00:00+00', '2024-07-14 23:59:59+00'); -- Nissan Leaf in Paris

-- Заполнение информацией таблицы Статус заказа / E16
INSERT INTO taxi_order_status (status_name) VALUES
('just_created'),       -- Заказ только создан
('driver_search'),      -- Идет поиск водителя
('driver_has_been_found'),  -- Водитель назначен
('ride_started'),       -- Поездка начата
('ride_completed'),     -- Поездка успешно завершена
('cancelled_by_client'),-- Отменен клиентом
('cancelled_by_driver');-- Отменен водителем

-- Заполнение информацией таблицы Тип оплаты / E14
INSERT INTO type_payment (payment_name) VALUES
('cash'),           -- Наличный расчет
('card'),           -- Безналичная оплата картой
('mobile_payment'), -- Мобильные платежи (Apple Pay/Google Pay)
('corporate');      -- Корпоративная оплата (безнал для юр. лиц)

-- Заполнение информацией таблицы Основание оплаты / E15
INSERT INTO basis_payment (payment_name) VALUES
('ride_payment'),     -- Оплата поездки клиентом
('car_rental');       -- Арендная плата от водителя

-- Заполнение информацией таблицы Входящие платежи / E10
INSERT INTO input_payment (
  type_payment_id,
  basis_payment_id,
  taxi_user_id,
  date,
  payment_sum
) VALUES
-- Платежи за поездки (без указания водителя)
(2, 1, 7, '2023-10-01 08:15:22+00', 500),  -- Безнал оплата поездки
(1, 1, 8, '2023-10-01 09:30:45+00', 1050),   -- Наличные за поездку

-- Арендные платежи от водителей (указываем driver_id)
(2, 2, 5, '2023-10-01 00:00:01+00', 45.00),      -- Дэвид Миллер аренда авто
(2, 2, 6, '2023-10-01 00:00:05+00', 42.00);       -- Джессика Дэвис аренда авто

-- Заполнение информацией таблицы Заказ / E8
INSERT INTO taxi_order (
  driver_id,
  client_id,
  dispatcher_id,
  taxi_order_status_id,
  input_payment_id,
  trip_type_id,
  start_date,
  end_date,
  start_point,
  end_point
) VALUES
-- Завершенные оплаченные заказы
(5, 7, 3, 5, 1, 1, '2023-10-01 08:00:00+00', '2023-10-01 08:25:00+00', 'Central Park, NYC', 'Times Square, NYC'),
(6, 8, 4, 5, 2, 2, '2023-10-01 09:15:00+00', '2023-10-01 09:45:00+00', 'Buckingham Palace, London', 'London Eye, London'),

-- Заказ с долгом (Lisa Martinez, client_id = 10)
(6, 10, 4, 5, NULL, 3, '2023-10-02 15:20:00+00', '2023-10-02 16:05:00+00', 'Eiffel Tower, Paris', 'Louvre Museum, Paris'),

-- Заказ от которого все отказываются для 4 запроса. он выполняется в текущем времени, статус поиск водителя
(NULL, 7, 4, 2, NULL, 3, '2024-10-01 09:15:00+00', NULL, 'Kensington High Street, London', 'Brick Lane, London');

-- Заказ поездка начата для демонстрации работы второй процедуры
-- (14, 7, 4, 4, NULL, 2, '2025-05-16 20:15:00+00', NULL, 'Eiffel Tower, Paris', 'Louvre Museum, Paris');

-- Заполнение информацией таблицы Отказы водителей / E9
INSERT INTO driver_rejection (
  driver_id,
  taxi_order_id,
  reason,
  date
) VALUES (
  5,                     -- driver_id = 5 (David Miller)
  2,                     -- taxi_order_id = 2 (заказ London Eye)
  'Too far from current location',  -- Причина отказа
  '2023-10-01 09:10:00+00'  -- Время отказа (до начала поездки)
),

(13, 4, 'Too far from current location', '2024-10-01 09:16:00+00'),
(14, 4, 'Too far from current location', '2024-10-01 09:17:00+00'),
(15, 4, 'Too far from current location', '2024-10-01 09:18:00+00'),
(5, 4, 'Too far from current location', '2024-10-01 09:19:00+00');

-- Заполнение информацией таблицы Исходящие платежи / E11
-- Выплата водителю David Miller (driver_id=5) за заказ №1 (Economy)
INSERT INTO output_payment (driver_id, date, payment_sum) VALUES
(5, '2023-10-01 18:00:00+00', 
  (SELECT 500 * (1 - profit_multiplier) 
   FROM trip_type WHERE trip_type_id = 1));

-- Выплата водителю Jessica Davis (driver_id=6) за заказ №2 (Comfort)
INSERT INTO output_payment (driver_id, date, payment_sum) VALUES
(6, '2023-10-01 18:00:00+00', 
  (SELECT 1050 * (1 - profit_multiplier) 
   FROM trip_type WHERE trip_type_id = 2));

-- Заполнение информацией таблицы Акт регистрации водителя или диспетчера / E13
INSERT INTO act_registration (admin_id, taxi_user_id) VALUES
-- Водители (driver_id = 5,6)
(1, 5),  -- David Miller зарегистрирован John Smith
(2, 6),  -- Jessica Davis зарегистрирована Emily Johnson

-- Диспетчеры (dispatcher_id = 3,4)
(1, 3),  -- Michael Williams зарегистрирован John Smith
(2, 4),  -- Sarah Brown зарегистрирована Emily Johnson

-- Владельцы (owner_id = 11,12)
(1, 11), -- James Wilson зарегистрирован John Smith
(2, 12); -- Sophia Garcia зарегистрирована Emily Johnson

