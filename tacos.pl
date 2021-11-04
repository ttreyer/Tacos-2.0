use Mojolicious::Lite;
use Mojo::SQLite;
use POSIX qw(strftime);

app->plugin('Config');

helper sizes => sub { 'M', 'L', 'L Mixte', 'XL', 'XXL', 'Giga' };
helper sizes_prices => sub { (M => 7, L => 8, 'L Mixte' => 9, XL => 15, XXL => 23, Giga => 31) };
helper sizes_max_meat => sub { my %max = (M => 1, L => 1, 'L Mixte' => 3, XL => 3, XXL => 4, Giga => 5); $max{ $_[1] } };
helper meats => sub { 'Viande hachée', 'Escalope de poulet', 'Cordon bleu', 'Merguez', 'Nuggets', 'Kebab', 'Soudjouk', 'Végétarien' };
helper garnishes => sub { 'Frites', 'Cheddar', 'Gruyère', 'Salade', 'Tomate', 'Oignons', 'Carottes', 'Cornichons' };
helper sauces => sub { 'Fromagère', 'Ketchup', 'Mayonnaise', 'Cocktail', 'Blanche', 'Barbecue', 'Américaine', 'Biggy burger', 'Tartare', 'Curry', 'Cheezy', 'Andalouse', 'Algérienne', 'Marocaine', 'Harissa', 'Samouraï', 'Poivre' };
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
-- 2 up
alter table hashtags add column created_at datetime default 0;
alter table tacos add column created_at datetime default 0;
-- 2 down
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
    created_at => strftime('%F %X', localtime),
  };

  my $max_meat_count = $c->sizes_max_meat($tacos->{size});
  my $message = "Il faut prendre $max_meat_count viandes avec cette taille!";
  if (@{ $c->every_param('meat') } <= $max_meat_count) {
    $message = 'Tacos ajouté!';
    $c->sqlite->db->insert('tacos', $tacos);
  }
  return $c->render('form', message => $message);
};
get '/hashtag' => 'hashtag';
post '/hashtag' => sub {
  my $c = shift;
  $c->sqlite->db->insert('hashtags', { name => $c->param('hashtag'), created_at => strftime('%F %X', localtime) });
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

<textarea cols="100" rows="10">Total: <%= $total %> CHF

% foreach my $tacos (@all_tacos) {
<%= $tacos->{name} %>: <%= price($tacos->{size}) %>.-
% }
</textarea><hr>

<textarea cols="100" rows="20">Bonjour, j'aimerais commander <%= scalar @all_tacos %> tacos :
<%= $sizes_label %>.
% foreach my $tacos (@all_tacos) {
=============================================
*<%= $tacos->{size} %>* :
*Viande* : <%= $tacos->{meat} %>
*Garniture* : <%= $tacos->{garnish} %>
*Sauce* : <%= $tacos->{sauce} %>
% }
=============================================
Livraison à l'arrêt M1 EPFL.
À 11h30.
Merci et bonne journée.</textarea>

@@ hashtag.html.ep
% layout 'main';
<h2 style="color:red">!!! en envoyant un hashtag, tu démarres une toute nouvelle commande !!!</h2>

<p>
  <img class="tacospin" src="https://media.giphy.com/media/3xz2BxlT8yngXMEX4Y/giphy.gif">
  <img class="tacospin" src="https://media.giphy.com/media/lDpFBflBkkxfq/giphy.gif">
  <img class="tacospin" src="https://media.giphy.com/media/3xz2BxlT8yngXMEX4Y/giphy.gif">
</p>

<form method="post" action="/hashtag">
  <label for="hashtag">Hashtag de la commande: </label>
  <input type="text" id="hashtag" name="hashtag">
  <input type="submit">
</form>

@@ form.html.ep
% layout 'main';
% my $hashtag = hashtag();

<p>
  <img class="tacospin" src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
  <img class="tacospin" src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
  <img class="tacospin" src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
</p>

<h2><%= $hashtag->{name} %></h2>
<h3><%= $hashtag->{created_at} %></h3>

%= form_for '/' => (method => 'POST') => begin
  <p>
    %= label_for 'name' => 'Say your name:'
    %= text_field 'name', id => 'name', required => 'required', autofocus => 'autofocus'
  </p>
  <p class="sizes">
    Taille:

    % foreach my $size (sizes()) {
      <span id="span-<%=$size%>" class="size tacosButton">
        %= radio_button size => $size, id => $size, required => 'required'
      	%= label_for $size => begin
          <%= $size %> (<%= sizes_max_meat($size) %> viandes, <%= price($size) %>.-)
          <span class="decoButton"></span>
        %= end
	        	
      </span>
    % }
  </p>
  <p class="meats">
    Viandes:

    % foreach my $meat (meats()) {
      <span id="span-<%=$meat%>" class="meat tacosButton">
        %= check_box meat => $meat, id => $meat
        %= label_for $meat => begin
          <%= $meat %>
          <span class="decoButton"></span>
        %= end
      </span>
    % }
  </p>
  <p class="garnishes">
    Garnitures:

    % foreach my $garnish (garnishes()) {
      <span id="span-<%=$garnish%>" class="garnish tacosButton">
        %= check_box garnish => $garnish, id => $garnish
        %= label_for $garnish => begin
          <%= $garnish %>
          <span class="decoButton <%= $garnish %>"></span>
        %= end
      </span>
    % }
  </p>

  <p class="sauces">
    Sauces:

    % foreach my $sauce (sauces()) {
    <span id="span-<%=$sauce%>" class="sauce tacosButton">
        %= check_box sauce => $sauce, id => $sauce
        %= label_for $sauce => begin
          <%= $sauce %>
          <span class="decoButton <%= $sauce %>" ></span>
        %= end
      </span>
    % }
  </p>

  %= submit_button 'ORDER MY TACOS'
% end

% foreach my $tacos (@{ tacos_to_order() }) {
<hr/>
Pour <%= $tacos->{name} %><br>
Size <%= $tacos->{size} %><br>
[<%= $tacos->{meat} %>],<br>
[<%= $tacos->{garnish} %>],<br>
[<%= $tacos->{sauce} %>]<br>
<a href="/delete/<%= $tacos->{id} %>" style="color:red">Supprimer ce tacos</a>
% }

<script>
let name = document.querySelector('#name')
name.addEventListener('keyup', () => localStorage.name = name.value)
name.value = localStorage.name || ''
</script>

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Enforced modularity for TACOS</title>
    <link rel="shortcut icon" href="/icons/icon-16.png" type="image/x-icon">
    <link rel="manifest" href="tacos.webmanifest">
    <link type="text/css" rel="stylesheet" href="tacos.css">
    <meta name="color-scheme" content="dark light">
    <style>
      % foreach my $garnish (garnishes()) {
        .tacosButton > input:checked + label .decoButton.<%= $garnish %> { background-image: url('garnishEnabled-<%= $garnish %>.svg'); }
      % }
      % foreach my $sauce (sauces()) {
        .tacosButton > input:checked + label .decoButton.<%= $sauce =~ tr/ /./r %> { background-image: url('sauceEnabled-<%= $sauce %>.svg'); }
      % }
    </style>
    <meta charset="utf-8">
  </head>
  <body>
    <h1>Mmmh TACOS</h1>
    <%== ($message) ? "<h2>$message</h2>" : undef %>
    <%= content %>
    <p><a href="/">Home</a> | <a href="/hashtag">Nouvelle commande</a> | <a href="/whatsapp">Message WhatsApp</a></p>
  </body>
</html>
