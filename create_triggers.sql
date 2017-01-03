create or replace function create_user_trigger_function() returns trigger as $body$
  begin
    perform create_activity('utilisateur ' || new.email || ' cree !');
    return new;
  end;
$body$ language 'plpgsql';

drop trigger if exists create_user_trigger on users;
create trigger create_user_trigger after insert on users
for each row execute procedure create_user_trigger_function();

create or replace function create_libraries_trigger_function() returns trigger as $body$
  begin
    perform create_activity('bibliotheque ' || new.name || ' creee !');
    return new;
  end;
$body$ language 'plpgsql';

drop trigger if exists create_libraries_trigger on libraries;
create trigger create_libraries_trigger after insert on libraries
for each row execute procedure create_libraries_trigger_function();

create or replace function create_authors_trigger_function() returns trigger as $body$
  begin
    perform create_activity('auteur ' || new.first_name || ' ' || new.last_name || ' cree !');
    return new;
  end;
$body$ language 'plpgsql';

drop trigger if exists create_authors_trigger on authors;
create trigger create_authors_trigger after insert on authors
for each row execute procedure create_authors_trigger_function();

create or replace function create_loans_trigger_function() returns trigger as $body$
  begin
    perform create_activity('pret ' || new.id || ' cree !');
    return new;
  end;
$body$ language 'plpgsql';

drop trigger if exists create_loans_trigger on loans;
create trigger create_loans_trigger after insert on loans
for each row execute procedure create_loans_trigger_function();
create or replace function delete_user_trigger_function() returns trigger as $body$
  begin
    perform create_activity('utilisateur ' || old.email || ' supprimé !');
    return old;
  end;
$body$ language 'plpgsql';

drop trigger if exists delete_user_trigger on users;
create trigger delete_user_trigger after delete on users
for each row execute procedure delete_user_trigger_function();

create or replace function delete_libraries_trigger_function() returns trigger as $body$
  begin
    perform create_activity('bibliothèque ' || old.name || ' supprimée !');
    return old;
  end;
$body$ language 'plpgsql';

drop trigger if exists delete_libraries_trigger on libraries;
create trigger delete_libraries_trigger after delete on libraries
for each row execute procedure delete_libraries_trigger_function();

create or replace function delete_authors_trigger_function() returns trigger as $body$
  begin
    perform create_activity('auteur ' || old.first_name || ' ' || old.last_name || ' supprimé !');
    return old;
  end;
$body$ language 'plpgsql';

drop trigger if exists delete_authors_trigger on authors;
create trigger delete_authors_trigger after delete on authors
for each row execute procedure delete_authors_trigger_function();
create or replace function date_after_update_1() returns trigger as $body$
  declare
    r record;
  begin
    for r in (
      select * from loans
      inner join exemplaires
      on exemplaires.id = loans.exemplaire_id
      inner join documents
      on documents.id = exemplaires.document_id
      where not returned and
      NEW.current_date + interval '2 day' = end_date
    ) LOOP
      raise notice 'Le document (%) appelé % est à rendre le %.', r.id, r.title, r.end_date;
    end LOOP;
    return null;
  end;
$body$ language 'plpgsql';

drop trigger if exists date_after_update_1_trigger on date;
create trigger date_after_update_1_trigger after update on date
for each row execute procedure date_after_update_1();

--
--
--

create or replace function date_after_update_2() returns trigger as $body$
-- suppression des reservations dont la end_date est passée
begin
  delete from reservations where end_date > get_current_date();
  return null;
end;
$body$ language 'plpgsql';

drop trigger if exists date_after_update_2_trigger on date;
create trigger date_after_update_2_trigger after update on date
for each row execute procedure date_after_update_2();

--
--
--

create or replace function date_after_update_3() returns trigger as $body$
-- ajout de 0.15€ par jour aux fees
-- d'un user pour chaque loan en retard
declare
  user record;
begin
  update users set fees = users.fees + 0.15 where id in (
    select users.id from users
    inner join loans
    on loans.user_id = users.id
    where not loans.returned
    and loans.end_date < get_current_date()
  );

  return null;
end;
$body$ language 'plpgsql';

drop trigger if exists date_after_update_3_trigger on date;
create trigger date_after_update_3_trigger after update on date
for each row execute procedure date_after_update_3();

--
--
--

create or replace function date_after_update_4() returns trigger as $body$
begin
  delete from loans
  where (get_current_date() - start_date) > 60
  and returned;
  return null;
end;
$body$ language 'plpgsql';

drop trigger if exists date_after_update_4_trigger on date;
create trigger date_after_update_4_trigger after update on date
for each row execute procedure date_after_update_4();
create or replace function loans_before_insert_0() returns trigger as $body$
  begin
    -- teste si utilisateur a des prêts en retard

    if (user_has_late_loans(new.user_id))
    then
      raise exception 'Utilisateur a au moins un document en retard !';
      return null;
    else
      return new;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_0_trigger on loans;
create trigger loans_before_insert_0_trigger before insert on loans
for each row execute procedure loans_before_insert_0();

create or replace function loans_before_insert_1() returns trigger as $body$
  declare
    existed int;
    loaned int;
  begin
    -- teste si la bibliothèque comporte un exemplaire du document

    select count(*) into existed
    from exemplaires
    where document_id=(
     select document_id
     from exemplaires
     where id=new.exemplaire_id
    )
    and library_id=(
     select library_id
     from exemplaires
     where id=new.exemplaire_id
    );

    select count(*) into loaned
    from loans
    where not returned
    and exemplaire_id=new.exemplaire_id;

    if (existed > loaned)
    then
      return new;
    else
      raise exception 'Aucun exemplaire disponible dans la bibliotheque';
      return null;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_1_trigger on loans;
create trigger loans_before_insert_1_trigger before insert on loans
for each row execute procedure loans_before_insert_1();

--
--
--

create or replace function loans_before_insert_2() returns trigger as $body$
  begin
    -- teste si l'utilisateur a une souscription
    -- peu importe son type de souscription

    if exists(select * from users
              where id = new.user_id
              and subscription_id is not null)
    then
      if exists(select * from users
                where id = new.user_id
                and subscription_id is not null
                and subscription_end_date >= get_current_date())
      then
        raise notice 'Date fin de souscription correcte !';
        return new;
      else
      raise exception 'Date fin de souscription dépassée !';
      return null;
      end if;
    else
      raise exception 'Utilisateur sans souscription !';
      return null;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_2_trigger on loans;
create trigger loans_before_insert_2_trigger before insert on loans
for each row execute procedure loans_before_insert_2();



create or replace function loans_before_insert_3() returns trigger as $body$
  begin
    -- teste si l'utilisateur peut preter le document
    -- on cherche l'utilisateur detenteur du pret
    -- on verifie que la souscription lui permet
    -- de preter le document

    if exists(select * from users
              where id = new.user_id
              and subscription_id is not null)
    then
      if exists(select * from users
                where id = new.user_id
                and subscription_id = (
                  select id from subscriptions
                  where type >= (
                    select type from documents
                    inner join exemplaires
                    on documents.id = exemplaires.document_id
                    where exemplaires.id = new.exemplaire_id limit 1
                  ) limit 1
                ))
      then
        return new;
      else
        raise exception 'Subscription ne permet pas demprunter';
        return null;
      end if;
    else
      return new;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_3_trigger on loans;
create trigger loans_before_insert_3_trigger before insert on loans
for each row execute procedure loans_before_insert_3();

create or replace function loans_before_insert_4() returns trigger as $body$
  begin
    if ((select count(*) from loans
         where user_id = new.user_id
         and not returned) < 40)

    then
      return new;
    else
      raise exception 'ne peut pas dépasser 40 emprunts au total';
      return null;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_4_trigger on loans;
create trigger loans_before_insert_4_trigger before insert on loans
for each row execute procedure loans_before_insert_4();

create or replace function loans_before_insert_5() returns trigger as $body$
  begin
    if ((select count(*) from loans
         where user_id = new.user_id
         and not returned
         and exemplaire_id in (
           select id from exemplaires
           where library_id = (
             select library_id from exemplaires
             where id = new.exemplaire_id limit 1
           )
         )) < 20)

    then
      return new;
    else
      raise exception 'Utilisateur a déjà 20 documents empruntés dans la bibliothèque';
      return null;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_5_trigger on loans;
create trigger loans_before_insert_5_trigger before insert on loans
for each row execute procedure loans_before_insert_5();

create or replace function loans_before_insert_6()
returns trigger as $body$
begin
  -- teste si l'utilisateur n'a pas plus de 15€ de frais

  if (select fees from users where id=new.user_id) < 15.00
  then
    return new;
  else
    raise notice 'Utilisateur a atteint 15 euros ou plus de frais';
    return null;
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_6_trigger on loans;
create trigger loans_before_insert_6_trigger before insert on loans
for each row execute procedure loans_before_insert_6();

--
--
--

create or replace function loans_before_insert_7() returns trigger as $body$
  begin
    if ((
        select count(*) from loans
        where not returned
        and user_id=new.user_id
        and exemplaire_id=new.exemplaire_id
      ) = 0) then return new;
    else
      raise exception 'ne peux pas emprunter car déjà emprunter et non retourné !';
      return null;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_7_trigger on loans;
create trigger loans_before_insert_7_trigger before insert on loans
for each row execute procedure loans_before_insert_7();

create or replace function loans_after_update_8() returns trigger as $body$
  declare
    r record;
  begin
    if (new.returned)
    then
      for r in (
        select * from reservations
        where exemplaire_id=new.exemplaire_id
        order by start_date asc limit 1
      ) loop
        raise notice 'Exemplaire % reservé est disponible !', r.exemplaire_id;
      end loop;
    end if;

    return new;
  end;
$body$ language 'plpgsql';

drop trigger if exists loans_after_update_8_trigger on loans;
create trigger loans_after_update_8_trigger after update on loans
for each row execute procedure loans_after_update_8();

--
--
--

create or replace function loans_after_update_9_0()
returns trigger as $body$
begin
  if (new.returned)
  then
    update reservations
    set end_date=get_current_date() + interval '7 day'
    where id=(
      select id from reservations
      where reservations.exemplaire_id=new.exemplaire_id
      and end_date is null
      order by start_date desc
      limit 1
    );
  end if;

  return new;
end;
$body$ language 'plpgsql';

drop trigger if exists loans_after_update_9_0_trigger on loans;
create trigger loans_after_update_9_0_trigger after update on loans
for each row execute procedure loans_after_update_9_0();

--
--
--

create or replace function loans_before_insert_10_0() returns trigger as $body$
-- emprunter au maximum 5 dvd
begin
  if ((select count(*) from loans
       inner join exemplaires
       on loans.exemplaire_id = exemplaires.id
       inner join documents
       on exemplaires.document_id= documents.id
       where user_id = new.user_id and type = 2) < 5)
  then
    return new;
  else
    raise exception 'Utilisateur a dépassé le nombre max de dvd autorisés !';
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_10_0_trigger on loans;
create trigger loans_before_insert_10_0_trigger before insert on loans
for each row execute procedure loans_before_insert_10_0();

--
--
--

create or replace function loans_before_insert_10() returns trigger as $body$
-- emprunter moins de 3 dvd nouveaux
begin
  if ((select count(*) from loans
       inner join exemplaires
       on loans.exemplaire_id = exemplaires.id
       inner join documents
       on exemplaires.document_id= documents.id
       where user_id = new.user_id and type = 2 and latest) < 3)
  then
    return new;
  else
    raise exception 'utilisateur a dépassé le nombre max de dvd nouveautés autorisés !';
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_10_trigger on loans;
create trigger loans_before_insert_10_trigger before insert on loans
for each row execute procedure loans_before_insert_10();

--
--
--

create or replace function loans_before_update_11() returns trigger as $body$
-- un prêt n'est pas renouvable s'il est réservé ou s'il est déjà en retard
begin
  if (is_loan_reserved(old.id) or is_loan_en_retard(old.id))
  then
    if (new.renewed > old.renewed)
    then
      raise exception 'Exemplaire déjà résérvé ou bien prêt en retard !';
    else
      return new;
    end if;
  else
    return new;
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_update_11_trigger on loans;
create trigger loans_before_update_11_trigger before update on loans
for each row execute procedure loans_before_update_11();

--
--
--

create or replace function loans_before_insert_12() returns trigger as $body$
-- Exemplaire déjà prêté !
begin
  if exists(
    select * from loans
    where exemplaire_id=new.exemplaire_id
    and not returned
  )
  then
    raise exception 'Exemplaire déjà prêté !';
  else
    return new;
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists loans_before_insert_12_trigger on loans;
create trigger loans_before_insert_12_trigger before insert on loans
for each row execute procedure loans_before_insert_12();
create or replace function reservation_before_insert_1() returns trigger as $body$
-- l'utilisateur n'a pas de document en retard
begin
  if (select count(*) from loans where user_id = new.user_id
      and not returned and end_date < get_current_date()) > 0
  then
  raise exception 'Utilisateur a au moins un document en retard';
    return null;
  else
    return new;
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists reservation_before_insert_1_trigger on reservations;
create trigger reservation_before_insert_1_trigger before insert on reservations
for each row execute procedure reservation_before_insert_1();



create or replace function reservation_before_insert_2() returns trigger as $body$
  begin
  -- utilisateur a moins de 5 reservations

  if (select count(*) from reservations
      where end_date is null
      and user_id = new.user_id) < 5
  then return new;
  else
    raise exception 'utilisateur a atteint le nb max de reservations autorisées';
        return null;
    end if;
  end;
$body$ language 'plpgsql';

drop trigger if exists reservation_before_insert_2_trigger on reservations;
create trigger reservation_before_insert_2_trigger before insert on reservations
for each row execute procedure reservation_before_insert_2();



create or replace function reservation_before_insert_3() returns trigger as $body$
declare
  l_id int;
  d_id int;
  nbdispo int;
  nbemprunte int;
begin
  select library_id into l_id from exemplaires
  where exemplaires.id = new.exemplaire_id limit 1;

  select document_id into d_id from exemplaires
  where exemplaires.id = new.exemplaire_id limit 1;

  select count(*) into nbdispo from exemplaires
  where exemplaires.library_id = l_id and exemplaires.document_id = d_id;

  select count(*) into nbemprunte from loans
  where not returned and loans.exemplaire_id in (
    select id from exemplaires
    where exemplaires.library_id = l_id and exemplaires.document_id = d_id
  );

  if (nbdispo = nbemprunte)
  then return new;
  else
    raise exception 'Au moins un exemplaire est disponible au prêt';
        return null;
  end if;
end;
$body$ language 'plpgsql';

drop trigger if exists reservation_before_insert_3_trigger on reservations;
create trigger reservation_before_insert_3_trigger before insert on reservations
for each row execute procedure reservation_before_insert_3();
create or replace function users_after_update()
returns trigger as $body$
begin
  if (new.fees = 15)
  then
    raise notice 'Utilisateur a atteint 15e de frais !';
  end if;

  return new;
end;
$body$ language 'plpgsql';

drop trigger if exists users_after_update_trigger on users;
create trigger users_after_update_trigger after update on users
for each row execute procedure users_after_update();
