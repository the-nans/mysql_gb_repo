use new_shop;

-- ================= ЗАДАНИЕ ПРО ТРАНЗАКЦИИ И ВРЕМЕННЫЕ СТРУКТУРЫ ДАННЫХ ============

-- только самые свежие 5 записей по полю created_at , красивенько. Удалять из основной таблицы мы ничего не будем, это 
-- нарушает наши представления о счастье будущих археологов 

create or replace view fresh_5 as
select * from users order by created_at desc limit 5;
select * from fresh_5 order by id; 

-- прочёс августа, без функции но с дополнительным скандинавским пафосом 
insert into users values (11, 'Харальд', '1986-03-03', '2018-08-01 14:14:03', '2020-12-02 17:05:34'), (12, 'Освальд', '1977-05-03', '2018-08-04 20:22:03', '2020-02-02 07:05:34'),
 (13, 'Торвальд', '1996-04-13', '2018-08-16 23:14:03', '2020-06-02 22:05:34'), (14, 'Зигмунд', '1991-11-07', '2018-08-17 12:14:03', '2020-12-22 11:05:34');

select aday.augustday, if(date(u.created_at) = aday.augustday, concat('Славный ', u.`name`,  ' пришёл в этот день!'), ' ') as reg_day  from
(select '2018-08-01' as augustday union all select '2018-08-02' union all select '2018-08-03' union all select '2018-08-04' union all select '2018-08-05' union all select '2018-08-06' union all select '2018-08-07' union all select '2018-08-08' 
								union all select '2018-08-09' union all select '2018-08-10' union all select '2018-08-11' union all select '2018-08-12' union all select '2018-08-13' union all select '2018-08-14' union all select '2018-08-15'
                                union all select '2018-08-16' union all select '2018-08-17' union all select '2018-08-18' union all select '2018-08-19' union all select '2018-08-20' union all select '2018-08-15' union all select '2018-08-16'
                                union all select '2018-08-23' union all select '2018-08-24' union all select '2018-08-25' union all select '2018-08-26' union all select '2018-08-27' union all select '2018-08-28' union all select '2018-08-29'
                                union all select '2018-08-30' union all select '2018-08-31')  aday left join users u on date(u.created_at) = aday.augustday;

-- представление названий и соответствующих им каталогов в базе данных

create or replace view in_join as select p.`name` as product_name, c.`name` as catalog_name from products p join catalogs c on p.catalog_id = c.id;

-- перенос пользователя между базами транзакцией 

start transaction;
insert into sample.users (id, name) (select id, name from new_shop.users where id = 1);
delete from new_shop.users where id  = 1;   -- для драматизма 
commit;

-- ================= ЗАДАНИЕ ПРО АДМИНИСТРИРОВАНИЕ БАЗ ДАННЫХ ========= 
-- задача-симулятор аналитика
use sandbox; 

create table accounts (
id int primary key auto_increment, 
username varchar(255),
pass varchar(255));

insert into accounts (username, pass) values 
('user1', ' eeff5809b250d691acf3a8ff8f210bd9 '),
('user2', ' e83cf18ac2b92787c3f4c20aae5f097e '),
('user3', ' b879e7867c53e22d9fbb4cce52984227 '),
('user4', ' 055ac94a0b0613584e022894d4c0b5f7 '),
('user5', ' 204f27327cfcd13c6e3a5f8cd9cd63db '),
('user6', ' ea4208d072deb977cff3fc81c04424d8 '),
('user7', ' 623944a4df969d117b53b54b1b7bc586 '),
('user8', ' 5344722fd38cd5f8de6a9874ffde28fe '),
('user9', ' 0ee98a37a999c2890f3dba6978a46baa '),
('user10', ' e42e9361dc345e90e519334b12169ef4 ');

create view acc_view as
select id, username from accounts; 

create user u1@'%' identified with sha256_password by 'pass1234';
grant select, show view  on sandbox.acc_view to u1@'%'; 

-- пользователь, которому можно всё и пользователь, который только спросить

create user shop@localhost identified with sha256_password by 'pass123'; 
grant all on new_shop.* to shop@localhost; 

create user shop_read@localhost identified with sha256_password by 'pass123'; 
grant SELECT on new_shop.* to shop_read@localhost; 

-- ================= ЗАДАНИЕ ПРО ХРАНИМЫЕ ПРОЦЕДУРЫ, ФУНКЦИИ, ТРИГГЕРЫ 
use new_shop;

-- фибоначчи на SQL

delimiter // 
create function fibonacci(num INT) 
returns int deterministic 
begin 
declare minusone int default 1; declare minustwo int default 1; 
declare temp int; declare i int; 
if (num = 0) then return 0; 
elseif (num = 1 or num = 2) then return 1; 
else  
set i = 3;  
while i <= num do 
set temp = minusone + minustwo;  
set minustwo = minusone; set minusone = temp;  
set i = i+1;  
end while;  
return temp; 
end if; 
end//

-- триггеры, следящие за заполняемостью полей name или description продукта 

delimiter //
create trigger check_sane_product_on_insert
before insert on `products` for each row
begin
if (new.`name` is NULL AND new.`description` is NULL)
then
signal sqlstate '45000' set message_text = 'At least name or description of product must be present' ;
end if;
end//

create trigger check_sane_product_on_update
before update on `products` for each row
begin
if (new.`name` is NULL AND new.`description` is NULL)
then
	set NEW.`name` = OLD.`name`;
    set NEW.`description` = OLD.`description`;
end if;
end//

delimiter ;

-- вежливая функция, идущая в ногу со временем 
Delimiter \\
CREATE DEFINER=`root`@`localhost` FUNCTION `hello`() RETURNS varchar(120) CHARSET utf8mb4
    NO SQL
BEGIN
if (time(now()) between time('00:00:00') and time('6:00:00')) then
return 'Good night';
elseif (time(now()) between time('6:00:01') and time('12:00:00')) then
return 'Good morning';
elseif (time(now()) between time('12:00:01') and time('18:00:00')) then
return 'Good day';
else
return 'Good evening';
END if;
end\\
Delimiter ;
select hello();
