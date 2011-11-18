package Acme::Shiin;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use URI;
use Carp;
use Lingua::JA::Regular::Unicode;

use 5.008_001;
our $VERSION = '0.01';

my $api_url = 'http://jlp.yahooapis.jp/FuriganaService/V1/furigana';

my $OMMIT_WORD_RE = do {
    my $words = join '|', qw(
        あ い う え お
        ぁ ぃ ぅ ぇ ぉ
        ゃ ゅ ょ っ
        を ー
    );
    qr/$words/;
};

my $H2A_MAP = {
    (map { $_ => 'k' } qw(か き く け こ)),
    (map { $_ => 's' } qw(さ し す せ そ)),
    (map { $_ => 't' } qw(た ち つ て と)),
    (map { $_ => 'n' } qw(な に ぬ ね の)),
    (map { $_ => 'h' } qw(は ひ ふ へ ほ)),
    (map { $_ => 'm' } qw(ま み む め も)),
    (map { $_ => 'y' } qw(や ゆ よ)),
    (map { $_ => 'r' } qw(ら り る れ ろ)),
    (map { $_ => 'w' } qw(わ)),
    (map { $_ => 'g' } qw(が ぎ ぐ げ ご)),
    (map { $_ => 'z' } qw(ざ ず ぜ ぞ)),
    (map { $_ => 'j' } qw(じ)),
    (map { $_ => 'd' } qw(だ ぢ づ で ど)),
    (map { $_ => 'b' } qw(ば び ぶ べ ぼ)),
    (map { $_ => 'p' } qw(ぱ ぴ ぷ ぺ ぽ)),
    (map { $_ => 'n' } qw(ん)),

};

sub new {
    my ($class, %args) = @_;
    croak 'Usage: Acme::Shiin->new(app_id => $yahoo_api_app_id)' unless $args{app_id};
    $args{ua} ||= LWP::UserAgent->new(agent => __PACKAGE__.'/ VERSION '.$VERSION);
    bless \%args, $class;
}

sub shiinize {
    my ($self, $stuff) = @_;
    my $request_uri = URI->new($api_url);
    $request_uri->query_form({
        appId    => $self->{app_id},
        sentence => $stuff,
        grade    => 1,
    });
    my $res = $self->{ua}->get($request_uri->as_string);
    croak $res->content unless $res->is_success;
    my $content = $res->decoded_content;

    my $sentence = '';
    my $original = '';
    my $state    = '';
    for my $line (split "\n", $content) {
        if ($state eq 'SubWordList') {
            $state = '' if $line =~ m|</SubWordList>|;
            next;
        }
        elsif ($line =~ m|<SubWordList>|) {
            $state = 'SubWordList';
            next;
        }

        if ($line =~ m|<Surface>([^<]+)</Surface>|) {
            $original = $1;
        }
        elsif ($line =~ m|<Furigana>([^<]+)</Furigana>|) {
            $sentence .= $1;
            $original = '';
        }
        elsif ($original) {
            $sentence .= $original;
            $original = '';
        }
    }

    my $ret = katakana2hiragana($sentence);
    $ret =~ s/$OMMIT_WORD_RE//g;
    $ret =~ s/(.)/$H2A_MAP->{$1||''}||$1/eg;

    return $ret;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Acme::Shiin - Consonantalize Japanese.

=head1 SYNOPSIS

  use utf8;
  use Acme::Shiin;

  my $shiin = Acme::Shiin->new(app_id => $yahoo_api_app_id);
  say $shiin->shiinize('マジレス'); # mjrk
  say $shiin->shiinize('確かに');   # tskn
  say $shiin->shiinize('どんびき'); # dnbk

=head1 DESCRIPTION

Acme::Shiin is Consonantalize Japanese.
C<< shiin >> is a C<< consonant >> in japanese.

Using Yahoo furigana API inside.
You should be have a Yahoo appId.

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 THANKS TO

gfx's mjrs

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< Lingua::JA::Regular::Unicode >>

=cut
