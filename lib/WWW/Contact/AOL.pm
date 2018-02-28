package WWW::Contact::AOL;

use Moose;
extends 'WWW::Contact::Base';
use Text::CSV;

our $VERSION   = '0.51';
our $AUTHORITY = 'cpan:FAYLAND';

sub get_contacts {
    my ($self, $email, $password) = @_;

    # reset
    $self->errstr(undef);

    my ( $username ) = split('@', $email);

    my $ua = $self->ua;
    $self->debug("start get_contacts from AOL mail");

    # if we don't identify as a known browser, AOL won't send us JavaScript with userId
    $ua->agent('Mozilla/5.0');

    # to form
    $self->get('https://my.screenname.aol.com/_cqr/login/login.psp?sitedomain=www.aol.com&lang=en&locale=us&authLev=0&siteState=https%3A%2F%2Fwww.aol.com%2F') || return;
    $self->submit_form(
        form_name => 'AOLLoginForm',
        fields    => {
            loginId  => $username,
            password => $password,
        },
    ) || return;
    my $content = $ua->content();
    if ($content =~ /name\=\"loginId\"/) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    $self->debug('Login OK');

    $self->get('https://mail.aol.com/');

    $self->get('https://mail.aol.com/webmail-std/en-us/suite');
    my ($user_id) = $ua->content =~ /var\s+userId\s*=\s*"(\w+)"/;
    return if not defined $user_id;

    $self->get("https://mail.aol.com/webmail/ExportContacts?command=all&format=csv&user=$user_id") || return;

    $content = $ua->content;
    my $csv = Text::CSV->new({ binary => 1 });
    open my $fh_csv, '<', \$content;
    my @header = @{ $csv->getline($fh_csv) };

    my @contacts;
    while (my $row_ref = $csv->getline($fh_csv)) {
        my %row;
        @row{@header} = @$row_ref;

        my $name = join ' ', grep {$_} @row{qw[ FirstName LastName ]};
        if ($row{NickName}) {
            $name .= ' ' if $name;    # no space if only NickName present
            $name .= "($row{NickName})";
        }

        my $email = $row{'E-mail'} || $row{'E-mail2'};
        if (not $email and $row{ScreenName}) {
            $email = $row{ScreenName} . '@aol.com';
        }
        next if not $email;

        push @contacts, { name => $name, email => $email };
    }
    $csv->eof or return;
    close $fh_csv;

    @contacts = grep { lc($_->{email}) ne lc($email) } @contacts; # skip himself

    return wantarray ? @contacts : \@contacts;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::AOL - Get contacts/addressbook from AOL Mail

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;

    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@aol.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get contacts from AOL Mail. extends L<WWW::Contact::Base>

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
