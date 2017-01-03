drop table if exists "activities" cascade;
drop table if exists "documents_authors" cascade;
drop table if exists "authors" cascade;
drop table if exists "date" cascade;
drop table if exists "documents" cascade;
drop table if exists "exemplaires" cascade;
drop table if exists "libraries" cascade;
drop table if exists "loans" cascade;
drop table if exists "reservations" cascade;
drop table if exists "subscriptions" cascade;
drop table if exists "users" cascade;

create table "activities" (
  "id" serial primary key,
  "content" text not null,
  "created_at" timestamp default current_timestamp
);

create table "authors" (
  "id" serial primary key,
  "civility" integer not null,
  "first_name" varchar not null,
  "last_name" varchar not null
);

create table "documents" (
  "id" serial primary key,
  "language" varchar not null,
  "title" varchar not null,
  "year" int not null,
  "isbn" varchar not null,
  "type" integer not null default 0,
  "price" decimal not null default 0.0,
  "latest" boolean not null default false
);

create table "documents_authors" (
  "id" serial primary key,
  "author_id" integer references authors(id) not null,
  "document_id" integer references documents(id) not null
);

create table "date" (
  "id" serial primary key,
  "current_date" date not null
);

create table "libraries" (
  "id" serial primary key,
  "name" varchar not null
);

create table "exemplaires" (
  "id" serial primary key,
  "shelf_number" varchar not null,
  "barcode" varchar not null,
  "locked" boolean not null default false,
  "library_id" integer references libraries(id) not null,
  "document_id" integer references documents(id) not null
);

create table "subscriptions" (
  "id" serial primary key,
  "name" varchar not null,
  "type" integer not null default 0
);

create table "users" (
  "id" serial primary key,
  "email" varchar not null,
  "first_name" varchar not null,
  "last_name" varchar not null,
  "fees" decimal not null default '0.0',
  "subscription_end_date" date,
  "subscription_id" int references subscriptions(id)
);

create table "loans" (
  "id" serial primary key,
  "start_date" date not null default get_current_date(),
  "end_date" date not null check (start_date < end_date),
  "returned" boolean not null default 'false',
  "renewed" integer not null default '0' check (renewed < 3),
  "user_id" integer references users(id) not null,
  "exemplaire_id" integer references exemplaires(id) not null
);

create table "reservations" (
  "id" serial primary key,
  "start_date" date not null default get_current_date() check (start_date >= get_current_date()),
  "end_date" date check (start_date < end_date),
  "user_id" integer references users(id) not null,
  "exemplaire_id" integer references exemplaires(id) not null
);
