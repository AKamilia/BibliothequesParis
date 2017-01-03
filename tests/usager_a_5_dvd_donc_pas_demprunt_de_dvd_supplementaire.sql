-- Les dvd sont limités à 5 à l'emprunt. usager a 5 dvds empruntés donc ne peux pas emprunter plus
create or replace function test()
returns void as $$
declare
  u_id int;
  s_id int;
  d_id int;
  l_id int;
  e_id int;
begin
  perform delete_all_tables();
  select into u_id create_user('Prénom 1', 'Nom 1', 'user-1@example.com');
  select into s_id create_subscription('Souscription 1', 2); -- 2 signifie possibilité d'emprunter type DVD
  perform add_subscription_to_user(s_id, u_id);
  select into d_id create_document('fr', 'Document 1', 2016, 'ISBN-abcdef', 2, 10.00, false); -- 2 signifie un DVD
  select into l_id create_library('diderot');

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC'); -- Erreur à cette ligne car déjà 5 dvd empruntés
  perform create_loan(e_id, u_id);
end;
$$ language plpgsql;

select test();
select * from users;
select * from documents;
select * from loans;
select * from date;
