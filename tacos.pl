use Mojolicious::Lite;
use Mojo::SQLite;

helper sizes => sub { 'M', 'L', 'L Mixte', 'XL', 'XXL', 'Giga' };
helper sizes_prices => sub { (M => 7, L => 8, 'L Mixte' => 9, XL => 15, XXL => 23, Giga => 31) };
helper sizes_max_meat => sub { my %max = (M => 1, L => 1, 'L Mixte' => 3, XL => 3, XXL => 4, Giga => 5); $max{ $_[1] } };
helper meats => sub { 'Viande hachée', 'Escalope de poulet', 'Cordon bleu', 'Merguez', 'Nuggets', 'Kebab', 'Soudjouk', 'Végétarien' };
helper garnishes => sub { 'Frites', 'Cheddar', 'Gruyère', 'Salade', 'Tomate', 'Oignons', 'Carottes', 'Cornichons' };
helper sauces => sub { 'Fromagère', 'Ketchup', 'Mayonnaise', 'Cocktail', 'Blanche', 'Barbecue', 'Américaine', 'Biggy burger', 'Tartare', 'Curry', 'Andalouse', 'Algérienne', 'Marocaine', 'Harissa', 'Samouraï', 'Poivre' };
helper price => sub { my %prices = shift->sizes_prices; $prices{ shift() } };

helper sqlite => sub { state $sqlite = Mojo::SQLite->new('sqlite:tacos.db') };
helper hashtag => sub { shift->sqlite->db->select('hashtags', undef, undef, { -desc => 'id' })->hash };
helper tacos_to_order => sub { $_[0]->sqlite->db->select('tacos', undef, { hashtag_id => $_[0]->hashtag->{id} })->hashes };

app->sqlite->migrations->name('tacos')->from_string(<<SQL)->migrate;
-- 1 up
create table hashtags (id integer primary key autoincrement, name text);
create table tacos (id integer primary key autoincrement, hashtag_id integer, name text, size text, meat text, garnish text, sauce text);
-- 1 down
drop table hashtags;
drop table tacos;
SQL

get '/' => 'form';
post '/' => sub {
  my $c = shift;

  my $tacos = {
    hashtag_id => $c->hashtag->{id},
    name => $c->param('name'),
    size => $c->param('size'),
    meat => join(', ', @{ $c->every_param('meat') }),
    garnish => join(', ', @{ $c->every_param('garnish') }),
    sauce => join(', ', @{ $c->every_param('sauce') }),
  };

  my $max_meat_count = $c->sizes_max_meat($tacos->{size});
  my $message = "Il faut prendre $max_meat_count viandes avec cette taille!";
  if (@{ $c->every_param('meat') } == $max_meat_count) {
    $message = 'Tacos ajouté!';
    $c->sqlite->db->insert('tacos', $tacos);
  }
  return $c->render('form', message => $message);
};
get '/hashtag' => 'hashtag';
post '/hashtag' => sub {
  my $c = shift;
  $c->sqlite->db->insert('hashtags', { name => $c->param('hashtag') });
  return $c->render('hashtag', message => 'Nouvelle commande!');
};

get '/delete/:tacos_id' => sub {
  my $c = shift;

  $c->sqlite->db->delete('tacos', { id => $c->stash('tacos_id') });
  $c->flash(message => 'Tacos supprimé!');
  return $c->redirect_to('/');
};

get '/whatsapp' => 'whatsapp';

app->defaults('message' => undef);
app->start;

__DATA__

@@ whatsapp.html.ep
% layout 'main';
% my %prices = sizes_prices();
% my $all_tacos = tacos_to_order();
% my @all_tacos = @{ $all_tacos };
% my $sizes_count = $all_tacos->reduce(sub { $a->{$b->{size}}++; $a }, {});
% my $sizes_label = join ', ', map { "$sizes_count->{$_} $_" } grep { $sizes_count->{$_} } sizes();
% my $total = $all_tacos->reduce(sub { $a + price($b->{size}) }, 0);

Total: <%= $total %> CHF<br><br>
% foreach my $tacos (@all_tacos) {
  <%= $tacos->{name} %>: <%= price($tacos->{size}) %>.-<br>
% }
<hr>

Bonjour, j'aimerais commander <%= scalar @all_tacos %> tacos :<br>
<%= $sizes_label %>.<br>
% foreach my $tacos (@all_tacos) {
=============================================<br>
*<%= $tacos->{size} %>* :<br>
*Viande* : <%= $tacos->{meat} %><br>
*Garniture* : <%= $tacos->{garnish} %> <br>
*Sauce* : <%= $tacos->{sauce} %><br>
% }
=============================================<br>
Livraison à <span contenteditable="true">l'arrêt M1 EPFL</span>.<br>
À <span contenteditable="true">11h30</span>.<br>
Merci et bonne journée.<br>

@@ hashtag.html.ep
% layout 'main';
<h2 style="color:red">!!! en envoyant un hashtag, tu démarres une toute nouvelle commande !!!</h2>

<p>
  <img width="30%" src="https://media.giphy.com/media/3xz2BxlT8yngXMEX4Y/giphy.gif">
  <img width="30%" src="https://media.giphy.com/media/lDpFBflBkkxfq/giphy.gif">
  <img width="30%" src="https://media.giphy.com/media/3xz2BxlT8yngXMEX4Y/giphy.gif">
</p>

<form method="post" action="/hashtag">
  <label for="hashtag">Hashtag de la commande: </label>
  <input type="text" id="hashtag" name="hashtag">
  <input type="submit">
</form>

@@ form.html.ep
% layout 'main';
% my $hashtag = hashtag();
% my $print_tacos = begin
  % my $tacos = shift;
  Pour <%= $tacos->{name} %><br>
  Size <%= $tacos->{size} %><br>
  [<%= $tacos->{meat} %>],<br>
  [<%= $tacos->{garnish} %>],<br>
  [<%= $tacos->{sauce} %>]<br>
  <a href="/delete/<%= $tacos->{id} %>" style="color:red">Supprimer ce tacos</a>
% end

<p>
  <img width="30%" src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
  <img width="30%" src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
  <img width="30%" src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
</p>

<h2><%= $hashtag->{name} %></h2>

%= form_for '/' => (method => 'POST') => begin
  <p>
    %= label_for 'name' => 'Say your name:'
    %= text_field 'name', id => 'name', required => 'required', autofocus => 'autofocus'
  </p>
  <p>
    Taille:

    % foreach my $size (sizes()) {
      %= label_for $size => "$size (" . price($size) . ".-)"
      %= radio_button size => $size, id => $size, required => 'required'
      |
    % }
  </p>
  <p>
    Viandes:

    % foreach my $meat (meats()) {
      %= label_for $meat => $meat
      %= check_box meat => $meat, id => $meat
      |
    % }
  </p>
  <p>
    Garnitures:

    % foreach my $garnish (garnishes()) {
      %= label_for $garnish => $garnish
      %= check_box garnish => $garnish, id => $garnish
      |
    % }
  </p>

  <p>
    Sauces:

    % foreach my $sauce (sauces()) {
      %= label_for $sauce => $sauce
      %= check_box sauce => $sauce, id => $sauce
      |
    % }
  </p>

  %= submit_button 'ORDER MY TACOS'
% end

% foreach my $tacos (@{ tacos_to_order() }) {
<hr/>
%= $print_tacos->($tacos)
% }

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Enforced modularity for TACOS</title>
    <meta charset="utf-8">
  </head>
  <body>
    <h1>Mmmh TACOS</h1>
    <%== ($message) ? "<h2>$message</h2>" : undef %>
    <%= content %>
    <p>
      <a href="/">Home</a> | <a href="/hashtag">Nouvelle commande</a> | <a href="/whatsapp">Message WhatsApp</a>
    </p>
  </body>
</html>
