use strict;
use warnings;
use v5.18;

use Mojolicious::Lite;
use Mojo::SQLite;

helper sqlite => sub { state $sqlite = Mojo::SQLite->new('sqlite:tacos.db') };
helper hashtag => sub { shift->sqlite->db->select('hashtags', undef, undef, { -desc => 'id' })->hash };
helper tacos_to_order => sub {
  my $app = shift;
  my $hashtag_id = $app->hashtag->{id};
  my $all_tacos = $app->sqlite->db->select('tacos', undef, { hashtag_id => $hashtag_id })->hashes;
  return $all_tacos;
};

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

  $c->sqlite->db->insert('tacos', $tacos);
  return $c->render('form', message => 'Tacos ajouté!');
};
get '/hashtag' => 'hashtag';
post '/hashtag' => sub {
  my $c = shift;
  my $new_hashtag = $c->param('hashtag');

  $c->sqlite->db->insert('hashtags', { name => $new_hashtag });
  return $c->render('hashtag', message => 'Nouvelle commande!');
};

get '/delete/:tacos_id' => sub {
  my $c = shift;

  $c->sqlite->db->delete('tacos', { id => $c->stash('tacos_id') });
  $c->flash(message => 'Tacos supprimé!');
  return $c->redirect_to('/');
};

app->defaults('message' => undef);
app->start;

__DATA__

@@ hashtag.html.ep
% layout 'main';
<h2 style="color:red">!!! en envoyant un hashtag, tu démarres une toute nouvelle commande !!!</h2>

<p>
  <img width="400px" src="https://media.giphy.com/media/3xz2BxlT8yngXMEX4Y/giphy.gif">
  <img width="400px" src="https://media.giphy.com/media/lDpFBflBkkxfq/giphy.gif">
  <img width="400px" src="https://media.giphy.com/media/3xz2BxlT8yngXMEX4Y/giphy.gif">
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
  <img src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
  <img src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
  <img src="https://media.giphy.com/media/7if9hGmIHjrTG/giphy.gif">
</p>

<h2><%= $hashtag->{name} %></h2>

<form method="post" action="/">
  <p>
    <label for="name">Say your name:</label>
    <input type="text" name="name" id="name">
  </p>
  <p>
    Taille:

    <label for="M">M (7.-)</label> <input type="radio" id="M" name="size" value="M"> |
    <label for="L">L (8.-)</label> <input type="radio" id="L" name="size" value="L"> |
    <label for="L Mixte">L Mixte (9.-)</label> <input type="radio" id="L Mixte" name="size" value="L Mixte"> |
    <label for="XL">XL (15.-)</label> <input type="radio" id="XL" name="size" value="XL"> |
    <label for="XXL">XXL (23.-)</label> <input type="radio" id="XXL" name="size" value="XXL"> |
    <label for="Giga">GIGA (7.-)</label> <input type="radio" id="Giga" name="size" value="Giga">
  </p>
  <p>
    Viandes:

    <label for="Viande hachée">Viande hachée</label> <input type="checkbox" id="Viande hachée" name="meat" value="Viande hachée"> |
    <label for="Escalope de poulet">Escalope de poulet</label> <input type="checkbox" id="Escalope de poulet" name="meat" value="Escalope de poulet"> |
    <label for="Cordon bleu">Cordon bleu</label> <input type="checkbox" id="Cordon bleu" name="meat" value="Cordon bleu"> |
    <label for="Merguez">Merguez</label> <input type="checkbox" id="Merguez" name="meat" value="Merguez"> |
    <label for="Nuggets">Nuggets</label> <input type="checkbox" id="Nuggets" name="meat" value="Nuggets"> |
    <label for="Kebab">Kebab</label> <input type="checkbox" id="Kebab" name="meat" value="Kebab"> |
    <label for="Soudjouk">Soudjouk</label> <input type="checkbox" id="Soudjouk" name="meat" value="Soudjouk"> |
    <label for="Végétarien">Végétarien</label> <input type="checkbox" id="Végétarien" name="meat" value="Végétarien">
  </p>
  <p>
    Garnitures:

    <label for="Frites">Frites</label> <input type="checkbox" id="Frites" name="garnish" value="Frites"> |
    <label for="Cheddar">Cheddar</label> <input type="checkbox" id="Cheddar" name="garnish" value="Cheddar"> |
    <label for="Gruyere">Gruyère</label> <input type="checkbox" id="Gruyere" name="garnish" value="Gruyere"> |
    <label for="Salade">Salade</label> <input type="checkbox" id="Salade" name="garnish" value="Salade"> |
    <label for="Tomate">Tomate</label> <input type="checkbox" id="Tomate" name="garnish" value="Tomate"> |
    <label for="Oignons">Oignons</label> <input type="checkbox" id="Oignons" name="garnish" value="Oignons"> |
    <label for="Carottes">Carottes</label> <input type="checkbox" id="Carottes" name="garnish" value="Carottes"> |
    <label for="Cornichons">Cornichons</label> <input type="checkbox" id="Cornichons" name="garnish" value="Cornichons">
  </p>

  <p>
    Sauces:

    <label for="Fromagère">Fromagère</label> <input type="checkbox" id="Fromagère" name="sauce" value="Fromagère"> |
    <label for="Ketchup">Ketchup</label> <input type="checkbox" id="Ketchup" name="sauce" value="Ketchup"> |
    <label for="Mayonnaise">Mayonnaise</label> <input type="checkbox" id="Mayonnaise" name="sauce" value="Mayonnaise"> |
    <label for="Cocktail">Cocktail</label> <input type="checkbox" id="Cocktail" name="sauce" value="Cocktail"> |
    <label for="Blanche">Blanche</label> <input type="checkbox" id="Blanche" name="sauce" value="Blanche"> |
    <label for="Barbecue">Barbecue</label> <input type="checkbox" id="Barbecue" name="sauce" value="Barbecue"> |
    <label for="Américaine">Américaine</label> <input type="checkbox" id="Américaine" name="sauce" value="Américaine"> |
    <label for="Biggy Burger">Biggy Burger</label> <input type="checkbox" id="Biggy Burger" name="sauce" value="Biggy Burger"> |
    <label for="Tartare">Tartare</label> <input type="checkbox" id="Tartare" name="sauce" value="Tartare"> |
    <label for="Curry">Curry</label> <input type="checkbox" id="Curry" name="sauce" value="Curry"> |
    <label for="Cheezy">Cheezy</label> <input type="checkbox" id="Cheezy" name="sauce" value="Cheezy"> |
    <label for="Andalouse">Andalouse</label> <input type="checkbox" id="Andalouse" name="sauce" value="Andalouse"> |
    <label for="Algérienne">Algérienne</label> <input type="checkbox" id="Algérienne" name="sauce" value="Algérienne"> |
    <label for="Marocaine">Marocaine</label> <input type="checkbox" id="Marocaine" name="sauce" value="Marocaine"> |
    <label for="Harissa">Harissa</label> <input type="checkbox" id="Harissa" name="sauce" value="Harissa"> |
    <label for="Samouraï">Samouraï</label> <input type="checkbox" id="Samouraï" name="sauce" value="Samouraï"> |
    <label for="Poivre">Poivre</label> <input type="checkbox" id="Poivre" name="sauce" value="Poivre">
  </p>

  <input type="submit" value="ORDER MY TACOS">
</form>

% foreach my $tacos (@{ tacos_to_order() }) {
<hr/>
<%== $print_tacos->($tacos) %>
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
  </body>
</html>
