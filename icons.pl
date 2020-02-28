use v5.20;
use Mojo::File 'path';
use Mojo::Template;

my %sauces_fill = ('Fromagère' => 'f8e9b5', Ketchup => 'c83427', Mayonnaise => 'fff0af', Cocktail => 'e29460', Blanche => 'fff', Barbecue => '3a1a13', 'Américaine' => 'e5843b', 'Biggy burger'=> 'e9d07e', Tartare => 'e3e1d5', Curry => 'f7c748', Cheezy => 'f7c788', Andalouse => 'c86815', 'Algérienne' => 'c58843', Marocaine => '75200d', Harissa => 'a00', 'Samouraï' => 'f0b175', Poivre => 'a68352');
my %garnish_fill = ('Frites' => 'f1ed35', 'Cheddar'=> 'fceb4e', 'Gruyère'=> 'fffbc1', 'Salade'=> '77ff49', 'Tomate'=> 'ff583a', 'Oignons'=> 'dfe8b0', 'Carottes'=> 'f2b715', 'Cornichons'=> '86e87f');
my %garnish_stroke = ('Frites' => 'e9cd00', 'Cheddar'=> 'ffd23f', 'Gruyère'=> 'f2ec9f', 'Salade'=> '20d302', 'Tomate'=> 'c61e00', 'Oignons'=> 'f7f7e1', 'Carottes'=> 'e89a00', 'Cornichons'=> '0eba01');

my $sauce_template = Mojo::Template->new(vars => 1);
$sauce_template->parse(path('templates/sauceEnabled.svg.ep')->slurp);

foreach my $sauce (keys %sauces_fill) {
  my $fill = $sauces_fill{ $sauce };
  my $sauce_icon = $sauce_template->process({ color => $fill });
  path("public/sauceEnabled-$sauce.svg")->spurt($sauce_icon);
}

my $garnish_template = Mojo::Template->new(vars => 1);
$garnish_template->parse(path('templates/garnishEnabled.svg.ep')->slurp);

foreach my $garnish (keys %garnish_fill) {
  my $fill = $garnish_fill{ $garnish };
  my $stroke = $garnish_stroke{ $garnish };
  my $garnish_icon = $garnish_template->process({ color1 => $fill, color2 => $stroke });
  path("public/garnishEnabled-$garnish.svg")->spurt($garnish_icon);
}
