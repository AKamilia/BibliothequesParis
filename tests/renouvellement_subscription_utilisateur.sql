-- Renouveller l'inscription d'un usager
create or replace function test()
returns void as $$
declare
  u_id int;
  s_id int;
begin
  perform delete_all_tables();
  select into u_id create_user('Prénom 1', 'Nom 1', 'user-1@example.com');
  select into s_id create_subscription('Souscription 1', 2);
  perform add_subscription_to_user(s_id, u_id);
  perform renew_subscription(u_id);
end;
$$ language plpgsql;

select test();
select * from users;

