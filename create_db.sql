-- Города / E1
CREATE TABLE IF NOT EXISTS city (
  city_id SERIAL PRIMARY KEY,
  city_name VARCHAR(50) NOT NULL
);

-- Роль пользователя / E5
CREATE TABLE IF NOT EXISTS role (
  role_id SERIAL PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL
);

-- Пользователь системы / E4
CREATE TABLE IF NOT EXISTS taxi_user (
  taxi_user_id SERIAL PRIMARY KEY,
  role_id INT REFERENCES role(role_id) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  phone_number VARCHAR(50) NOT NULL,
  inn TEXT,
  debit FLOAT DEFAULT 0,
  registration_date TIMESTAMPTZ NOT NULL
);

-- Таксопарки / E2
CREATE TABLE IF NOT EXISTS taxi_pool (
  taxi_pool_id SERIAL PRIMARY KEY,
  city_id INT REFERENCES city(city_id) NOT NULL,
  admin_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  owner_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  address TEXT NOT NULL,
  description TEXT NOT NULL
);

-- Тип поездки / E3
CREATE TABLE IF NOT EXISTS trip_type (
  trip_type_id SERIAL PRIMARY KEY,
  trip_name VARCHAR(100) NOT NULL,
  trip_description TEXT NOT NULL,
  trip_tariff FLOAT NOT NULL,
  trip_min_price FLOAT NOT NULL,
  profit_multiplier FLOAT NOT NULL CHECK (profit_multiplier >= 0 AND profit_multiplier <= 1)
);

-- Тип автомобиля / E12
CREATE TABLE IF NOT EXISTS type_car (
  type_car_id SERIAL PRIMARY KEY,
  type_car_name TEXT NOT NULL
);

-- Автомобиль / E6
CREATE TABLE IF NOT EXISTS car (
  car_registration_id SERIAL PRIMARY KEY,
  type_car_id INT REFERENCES type_car(type_car_id) NOT NULL,
  owner_id INT REFERENCES taxi_pool(taxi_pool_id) NOT NULL,
  car_brand_name TEXT NOT NULL,
  rental_price FLOAT NOT NULL,
  maintenance_price FLOAT NOT NULL
);

-- Договор о сотрудничестве / E7
CREATE TABLE IF NOT EXISTS contract (
  contract_id SERIAL PRIMARY KEY,
  car_registration_id INT REFERENCES car(car_registration_id) NOT NULL,
  admin_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  taxi_user_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  -- добавлено для первой процедуры, водитель заключает контракт именно с таксопарком
  taxi_pool_id INT REFERENCES taxi_pool(taxi_pool_id) NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL
  CONSTRAINT valid_contract_dates CHECK (end_date >= start_date)
);

-- Статус заказа / E16
CREATE TABLE IF NOT EXISTS taxi_order_status (
  taxi_order_status_id SERIAL PRIMARY KEY,
  status_name VARCHAR(100) NOT NULL
);

-- Тип оплаты / E14
CREATE TABLE IF NOT EXISTS type_payment (
  type_payment_id SERIAL PRIMARY KEY,
  payment_name VARCHAR(100) NOT NULL
);

-- Основание оплаты / E15
CREATE TABLE IF NOT EXISTS basis_payment (
  basis_payment_id SERIAL PRIMARY KEY,
  payment_name VARCHAR(100) NOT NULL
);

-- Входящие платежи / E10
CREATE TABLE IF NOT EXISTS input_payment (
  input_payment_id SERIAL PRIMARY KEY,
  type_payment_id INT REFERENCES type_payment(type_payment_id) NOT NULL,
  basis_payment_id INT REFERENCES basis_payment(basis_payment_id) NOT NULL,
  taxi_user_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  payment_sum FLOAT NOT NULL
);

-- Заказ / E8
CREATE TABLE IF NOT EXISTS taxi_order (
  taxi_order_id SERIAL PRIMARY KEY,
  driver_id INT REFERENCES taxi_user(taxi_user_id), -- Может принимать значение NULL, см. первый триггер
  client_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  dispatcher_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  taxi_order_status_id INT REFERENCES taxi_order_status(taxi_order_status_id) NOT NULL,
  input_payment_id INT REFERENCES input_payment(input_payment_id), -- заказ оплачивается в конце, его стоимость записывается в задолженность клиента
  trip_type_id INT REFERENCES trip_type(trip_type_id) NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ, -- в начале выполнения заказа это поле NULL
  start_point TEXT NOT NULL,
  end_point TEXT NOT NULL
  CONSTRAINT valid_taxi_order_dates CHECK (end_date >= start_date)
);

-- Отказы водителей / E9
CREATE TABLE IF NOT EXISTS driver_rejection (
  driver_rejection_id SERIAL PRIMARY KEY,
  driver_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  taxi_order_id INT REFERENCES taxi_order(taxi_order_id) NOT NULL,
  reason TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL
);

-- Исходящие платежи / E11
CREATE TABLE IF NOT EXISTS output_payment (
  output_payment_id SERIAL PRIMARY KEY,
  driver_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  payment_sum FLOAT NOT NULL
);

-- Акт регистрации водителя или диспетчера / E13
CREATE TABLE IF NOT EXISTS act_registration (
  act_registration_id SERIAL PRIMARY KEY,
  admin_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL,
  taxi_user_id INT REFERENCES taxi_user(taxi_user_id) NOT NULL
);

-- Отказы клиентов / E17
CREATE TABLE IF NOT EXISTS client_rejection (
  client_rejection_id SERIAL PRIMARY KEY,
  taxi_order_id INT REFERENCES taxi_order(taxi_order_id) NOT NULL,
  reason TEXT,
  date TIMESTAMPTZ NOT NULL
);
