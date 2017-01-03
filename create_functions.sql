create or replace function create_activity(text)
returns void as $$
begin
  insert into activities("content", "created_at") values ($1, current_timestamp);
end;
$$ language plpgsql;

create or replace function delete_activity(int)
returns void as $$
begin
  delete from activities where id=$1;
end;
$$ language plpgsql;
create or replace function create_author(int, varchar, varchar)
returns int as $$
declare index int;
begin
  insert into authors("civility", "first_name", "last_name")
  values ($1, $2, $3)
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function delete_author(int)
returns void as $$
begin
  delete from authors where id=$1;
end;
$$ language plpgsql;
create or replace function create_date(date)
returns void as $$
begin
  insert into date("current_date") values ($1);
end;
$$ language plpgsql;

create or replace function get_current_date()
returns date as $$
declare
  d date;
begin
  select "current_date" into d from date limit 1;
  return d;
end;
$$ language plpgsql;

create or replace function increment_date()
returns void as $$
begin
  update date set "current_date" = (
    select "current_date" from date limit 1
  ) + interval '1 day';
end;
$$ language plpgsql;

create or replace function add_to_date(int)
returns void as $$
begin
  update date set "current_date" = (
    select "current_date" from date limit 1
  ) + ($1 || ' day')::interval;
end;
$$ language plpgsql;
create or replace function delete_all_tables()
returns void as $$
begin
  delete from "activities" cascade;
  delete from "loans" cascade;
  delete from "reservations" cascade;
  delete from "exemplaires" cascade;
  delete from "documents_authors" cascade;
  delete from "documents" cascade;
  delete from "authors" cascade;
  delete from "libraries" cascade;
  delete from "users" cascade;
  delete from "subscriptions" cascade;
end;
$$ language plpgsql;
create or replace function create_document(varchar, varchar, varchar, varchar, int, decimal, boolean)
returns int as $$
declare index int;
begin
  insert into documents("language","title","year","isbn","type","price","latest")
  values ($1, $2, $3, $4, $5, $6, $7)
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function delete_document(int)
returns void as $$
begin
  delete from documents where id=$1;
end;
$$ language plpgsql;
create or replace function create_document_author(int, int)
returns int as $$
declare index int;
begin
  insert into documents_authors("document_id", "author_id")
  values ($1, $2)
  returning id into index;
  return index;
end;
$$ language plpgsql;
create or replace function create_exemplaire(integer, integer, varchar, varchar)
returns int as $$
declare index int;
begin
  insert into exemplaires("document_id", "library_id", "shelf_number", "barcode")
  values ($1, $2, $3, $4)
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function delete_exemplaire(int)
returns void as $$
begin
  delete from exemplaires where id=$1;
end;
$$ language plpgsql;
create or replace function create_library(varchar)
returns int as $$
declare index int;
begin
  insert into libraries("name") values ($1)
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function delete_library(int)
returns void as $$
begin
  delete from libraries where id=$1;
end;
$$ language plpgsql;

create or replace function update_library(int, varchar)
returns void as $$
begin
  update libraries set name=$2 where id=$1;
end;
$$ language plpgsql;
create or replace function show_exemplaires()
returns table (
  "Référence" int,
  "Nom du document" varchar,
  "Nom de la bibliothèque" varchar,
  "Nombre d'exemplaire dans la bibliothèque" bigint) as $$
begin
  return query
    select exemplaires.id, documents.title, libraries.name, count(exemplaires.id)
    from exemplaires
    inner join documents
    on exemplaires.document_id = documents.id
    inner join libraries
    on exemplaires.library_id = libraries.id
    group by libraries.id, exemplaires.id, documents.title
    order by exemplaires.id asc;
end;
$$ language plpgsql;

create or replace function show_libraries()
returns table (
  "Référence" int,
  "Nom de la bibliothèque" varchar,
  "Nombre de documents" bigint,
  "Nombre d'exemplaires" bigint,
  "Nombre total de prêts" bigint) as $$
begin
  return query
    select libraries.id, libraries.name, count(distinct documents.id), count(exemplaires.id), count(loans.id)
    from libraries
    left join exemplaires
    on libraries.id = exemplaires.library_id
    left join documents
    on exemplaires.document_id = documents.id
    left join loans
    on loans.exemplaire_id = loans.id
    group by documents.id, libraries.id;
end;
$$ language plpgsql;

create or replace function show_loans()
returns table (
  "Référence" int,
  "Date de début" date,
  "Date de fin" date,
  "Retourné?" boolean,
  "Prénom de l'utilisateur" varchar,
  "Nom de l'utilisateur" varchar,
  "Nom de la bibliothèque" varchar,
  "Nom du document" varchar) as $$
begin
  return query
    select loans.id, loans.start_date, loans.end_date, loans.returned, users.first_name, users.last_name, libraries.name, documents.title
    from loans
    inner join exemplaires
    on loans.exemplaire_id=exemplaires.id
    inner join documents
    on documents.id=exemplaires.document_id
    inner join libraries
    on exemplaires.library_id=libraries.id
    inner join users
    on loans.user_id=users.id
    group by loans.id, users.first_name, users.last_name, libraries.name, documents.title;
end;
$$ language plpgsql;
create or replace function create_loan(integer, integer)
returns int as $$
declare index int;
begin
  insert into loans("exemplaire_id", "user_id", "end_date")
  values ($1, $2, get_current_date() + interval '21 days')
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function user_has_late_loans(integer)
returns boolean as $$
declare r_bool boolean;
begin
  select into r_bool exists(
    select 1 from loans where user_id = $1
    and not returned and end_date < get_current_date()
  );

  return r_bool;
end;
$$ language plpgsql;

create or replace function delete_loan(integer)
returns void as $$
begin
  delete from loans where id=$1;
end;
$$ language plpgsql;

create or replace function return_document(integer)
returns void as $$
begin
  update loans set returned=true where id=$1;
end;
$$ language plpgsql;

create or replace function lost_loan(integer)
returns void as $$
begin
  update users set fees = users.fees + (
    select price from documents
    where id = (
      select document_id from exemplaires
      where exemplaires.id = (select exemplaire_id from loans where id = $1)
    )
  ) where id = (select user_id from loans where id = $1);
end;
$$ language plpgsql;


create or replace function renouvelement_pret(integer)
returns void as $$
begin
  update loans
  set renewed = loans.renewed + 1,
  end_date = loans.end_date + interval '21 days'
  where id = $1;
end;
$$ language plpgsql;

create or replace function is_loan_reserved(integer)
returns boolean as $$
declare
  r_count int;
begin
  select count(*) into r_count from reservations
  where reservations.exemplaire_id = (
    select exemplaire_id from loans where id = $1
  ) and reservations.end_date is null;

  return r_count > 0;
end;
$$ language plpgsql;

create or replace function is_loan_en_retard(integer)
returns boolean as $$
declare
  r_bool boolean;
begin
  select not returned and end_date <= get_current_date()
  into r_bool from loans where id = $1;
  return r_bool;
end;
$$ language plpgsql;
create or replace function create_reservation(integer, integer)
returns int as $$
declare index int;
begin
  insert into reservations("exemplaire_id", "user_id") values ($1, $2)
  returning id into index;
  return index;
end;
$$ language plpgsql;
-- recherche par titre et par auteur
create or replace function search_by_title(t text)
returns table (
  "Id" int,
  "Titre" varchar,
  "Prénom" varchar,
  "Nom" varchar,
  "Bibliothèque" varchar,
  "Exemplaires" bigint,
  "Exemplaires disponibles" bigint,
  "Exemplaires prêtés" bigint) as $$
begin
    return query
    select documents.id,
           documents.title,
           authors.first_name,
           authors.last_name,
           libraries.name,
           count(exemplaires.id),
           count(exemplaires.id) - count(loans.id),
           count(loans.id)
    from documents
    left outer join documents_authors
    on documents_authors.document_id = documents.id
    left outer join authors
    on documents_authors.author_id = authors.id
    left outer join exemplaires
    on exemplaires.document_id = documents.id
    left outer join libraries
    on exemplaires.library_id = libraries.id
    left outer join loans
    on loans.exemplaire_id = exemplaires.id
    where documents.title like '%' || t || '%' or
    authors.first_name    like '%' || t || '%' or
    authors.last_name     like '%' || t || '%'
    and loans.returned = false
    group by libraries.id,
             libraries.name,
             documents.id,
             authors.first_name,
             authors.last_name;
end;
$$ language plpgsql;

create or replace function search_by_mail(m text)
returns table (i int,em varchar, fn varchar, lna varchar, fes decimal, sid int) as $$
begin
  return query select * from users where email like '%'||m||'%';
end;
$$ language plpgsql;

create or replace function search_lib_by_name(na text)
returns table (i int,n varchar) as $$
begin
  return query
    select * from libraries where name like '%'||na||'%';
end;
$$ language plpgsql;
create or replace function create_subscription(varchar, int)
returns int as $$
declare index int;
begin
  insert into subscriptions("name", "type") values ($1, $2)
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function delete_subscription(int)
returns void as $$
begin
  delete from subscriptions where id=$1;
end;
$$ language plpgsql;

create or replace function add_subscription_to_user(int, int)
returns void as $$
begin
  update users
  set subscription_id = $1,
  subscription_end_date = get_current_date() + interval '1 year'
  where id=$2;
end;
$$ language plpgsql;

create or replace function renew_subscription(int)
returns void as $$
begin
  update users set
  subscription_end_date = users.subscription_end_date + interval '1 year'
  where id=$1;
end;
$$ language plpgsql;
create or replace function create_user(varchar, varchar, varchar)
returns int as $$
declare index int;
begin
  insert into users("first_name", "last_name", "email") values ($1, $2, $3)
  returning id into index;
  return index;
end;
$$ language plpgsql;

create or replace function delete_user(int)
returns void as $$
begin
  delete from users where id=$1;
end;
$$ language plpgsql;

create or replace function show_users()
  returns table (
  "Référence" int,
  "Prénom" varchar,
  "Nom" varchar,
  "Email" varchar,
  "Nom de la souscription" varchar,
  "Type inscription" int,
  "Frais" decimal) as $$
begin
  return query
    select users.id, first_name, last_name, email, subscriptions.name, subscriptions.type, users.fees
    from users inner join subscriptions
    on subscriptions.id = users.subscription_id;
end;
$$ language plpgsql;
