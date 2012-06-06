package WWW::Contact;

use Class::MOP ();
use Moose;

our $VERSION   = '0.49';
our $AUTHORITY = 'cpan:FAYLAND';

has 'errstr'   => ( is => 'rw', isa => 'Maybe[Str]' );
has 'supplier_pattern' => (
    is  => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    default => sub { [] }
);
has 'known_supplier' => (
    is  => 'rw',
    isa => 'HashRef',
    auto_deref => 1,
    default => sub {
        {
            'gmail.com'      => 'GoogleContactsAPI',
            'ymail.com'      => 'Yahoo',
            'rocketmail.com' => 'Yahoo',
            'rediffmail.com' => 'Rediffmail',
            'aol.com'        => 'AOL',
            'indiatimes.com' => 'Indiatimes',
            'lycos.com'      => 'Lycos',
            
            # cn
            '163.com'        => 'CN::163',
            'yeah.net'       => 'CN::163',
            'netease.com'    => 'CN::163',
            'popo.163.com'   => 'CN::163',

            # Mail
            'mail.com'       => 'Mail',
            'email.com'      => 'Mail',
            'iname.com'      => 'Mail',
            'cheerful.com'   => 'Mail',
            'consultant.com' => 'Mail',
            'europe.com'     => 'Mail',
            'mindless.com'   => 'Mail',
            'earthling.com'  => 'Mail',
            'myself.com'     => 'Mail',
            'techie.com'     => 'Mail',
            'usa.com'        => 'Mail',
            'writeme.com'    => 'Mail',
            
            # hotmail
            'hotmail.com'       => 'Hotmail',
            'live.com'          => 'Hotmail',
            'compaq.net'        => 'Hotmail',
            'hotmail.co.jp'     => 'Hotmail',
            'hotmail.co.uk'     => 'Hotmail',
            'hotmail.de'        => 'Hotmail',
            'hotmail.fr'        => 'Hotmail',
            'hotmail.it'        => 'Hotmail',
            'messengeruser.com' => 'Hotmail',
            'msn.com'           => 'Hotmail',
            'passport.com'      => 'Hotmail',
            'webtv.net'         => 'Hotmail',
            'live.co.uk'        => 'Hotmail',

            # bg
            'abv.bg'            => 'BG::Abv',
            'gbg.bg'            => 'BG::Abv',
            'gyuvectch.bg'      => 'BG::Abv',
            'mail.bg'           => 'BG::Mail',
        }
    }
);

has 'social_network' => (
    is  => 'rw',
    isa => 'HashRef',
    auto_deref => 1,
    default => sub {
        {
            # Social networks.
            'plaxo'    => 'Plaxo',
            'Hotmail'  => 'Hotmail',
            'Gmail'    => 'Gmail', # YYY? use GoogleContactsAPI?
        }
    }
);

has 'supplier_args' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has 'resolve' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has 'resolve_domain' => (
    is      => 'ro',
    isa     => 'Net::DNS::Resolver',
    lazy    => 1,
    default => sub {
        require Net::DNS::Resolver;
        Net::DNS::Resolver->new;
    },
);

sub get_contacts {
    my $self = shift;
    my ( $email, $password, $social_network ) = @_;
    
    unless ( $email and $password ) {
        $self->errstr('Both email and password are required.');
        return;
    }
    
    unless ( $email =~ m/^(.+)\@(([^.]+)\.(.+))$/ ) {
        $self->errstr('You must supply full email address.');
        return;
    }

    # get supplier module
    my $supplier;
    if($social_network) {
        $social_network = lc($social_network);
        $supplier = $self->get_supplier_by_socialnetwork($social_network);
    } else {
        $supplier = $self->get_supplier_by_email($email);
    }
    unless ($supplier) {
        if($social_network) {
            $self->errstr("$social_network is not supported yet.");
        } else {
            $self->errstr("$email is not supported yet.");
        }
        return;
    }
    
    my $module = 'WWW::Contact::' . $supplier;
    Class::MOP::load_class($module);
    my $wc = $module->new( $self->supplier_args );
    
    # reset
    $self->errstr(undef);
    
    my $contacts = $wc->get_contacts( $email, $password );

    if ( $wc->errstr ) {
        $self->errstr( $wc->errstr );
        return;
    } else {
        return wantarray ? @$contacts : $contacts;
    }
}

sub get_supplier_by_email {
    my ($self, $email) = @_;

    my %known_supplier = $self->known_supplier;

    my ($username, $domain) = split('@', $email);
    
    if ( exists $known_supplier{ $domain } ) {
        return $known_supplier{ $domain };
    }
    
    # @yahoo.com @yahoo.XX @XX.yahoo.XX
    if ( $email =~ /[\@\.]yahoo\./ ) {
        return 'Yahoo';
    }
    
    my @supplier_pattern = $self->supplier_pattern;
    foreach my $supplier (@supplier_pattern) {
        my $pattern = $supplier->{pattern};
        my $mtype   = ref($pattern);
        if ( $mtype eq 'Regexp' and $email =~ $pattern ) {
            return $supplier->{supplier};
        } elsif ( $domain eq $pattern ) {
            return $supplier->{supplier};
        }
    }
    
    # resolve domain
    my $r = $self->resolve;
    return $r->{ $domain } if exists $r->{ $domain };
    
    # warn 'resolve domain';
    foreach my $mx ($self->resolve_domain->query($domain, 'MX')) {
        for ($mx->answer) {
            # google corporate mail
            return $r->{ $domain } = $known_supplier{'gmail.com'} if $_->exchange =~ /google(?:mail)?\.com$/i;
        }
    }
    
    return;
}

sub get_supplier_by_socialnetwork {
    my ($self, $social_network) = @_;

    my %social_supplier = $self->social_network;

    if ( exists $social_supplier{ $social_network } ) {
        return $social_supplier{ $social_network };
    }

    return;
}

sub register_supplier {
    my ($self, $pattern, $supplier) = @_;

    unshift @{ $self->supplier_pattern }, { pattern => $pattern, supplier => $supplier };
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact - Get contacts/addressbook from Web

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;
    
    # Get contacts from email providers.
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('fayland@gmail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr; # like 'Wrong Username or Password'
    } else {
        print Dumper(\@contacts);
    }
    
    # Get contacts from social networks (eg: Plaxo)
    my $ws       = WWW::Contact->new();
    # Note that the last argument for get_contacts() is mandatory,
    # or else it will try to fetch contacts from gmail.com
    my @contacts = $ws->get_contacts('itsa@gmail.com', 'password', 'plaxo');
    my $errstr   = $ws->errstr;
    if ($errstr) {
        die $errstr; # like 'Wrong Username or Password'
    } else {
        print Dumper(\@contacts);
    }
    

=head1 DESCRIPTION

Get contacts/addressbook from public websites

=head1 SUPPORTED EMAIL SUPPLIER

=over 4

=item Gmail

L<WWW::Contact::Gmail> by Fayland Lam, DEPRECATED for L<WWW::Contact::GoogleContactsAPI>

=item Yahoo! Mail

L<WWW::Contact::Yahoo> by Fayland Lam

=item Rediffmail

L<WWW::Contact::Rediffmail> by Sachin Sebastian

=item mail.163.com

L<WWW::Contact::CN::163> by Fayland Lam

=item AOL

L<WWW::Contact::AOL> by Fayland Lam

=item Mail

L<WWW::Contact::Mail> by Sachin Sebastian

=item Hotmail/Live Mail

L<WWW::Contact::Hotmail> by Fayland Lam

=item Indiatimes

L<WWW::Contact::Indiatimes> by Sachin Sebastian

=item Lycos

L<WWW::Contact::Lycos> by Sachin Sebastian

=item Plaxo

L<WWW::Contact::Plaxo> by Sachin Sebastian

=item GoogleContactsAPI

L<WWW::Contact::GoogleContactsAPI> by Fayland Lam, using Google Contacts Data API

=item abv.bg

L<WWW::Contact::BG::Abv> by Dimitar Petrov

=item mail.bg

L<WWW::Contact::BG::Mail> by Dimitar Petrov

=back

=head1 METHODS

=head2 register_supplier

To use custom supplier, we must register within WWW::Contact

    $wc->register_supplier( qr/\@a\.com$/, 'Unknown' );
    $wc->register_supplier( 'a.com', 'Unknown' );

The first arg is a Regexp or domain from email postfix. The second arg is the according module postfix like 'Unknown' from WWW::Contact::Unknown

=head2 get_supplier_by_email

get supplier by email.

    my $supplier = $wc->get_supplier_by_email('a@gmail.com'); # 'GoogleContactsAPI'
    my $supplier = $wc->get_supplier_by_email('a@a.com');     # 'Unknown'

=head2 get_supplier_by_socialnetwork

get supplier by social network name.

    my $supplier = $wc->get_supplier_by_socialnetwork('plaxo'); # 'Plaxo'

=head1 HOW TO WRITE YOUR OWN MODULE

Please read L<WWW::Contact::Base> and examples: L<WWW::Contact::Yahoo> and L<WWW::Contact::Plaxo>

Assuming we write a custom module as WWW::Contact::Unknown

    package WWW::Contact::Unknown;
    
    use Moose;
    extends 'WWW::Contact::Base';
    
    sub get_contacts {
        my ($self, $email, $password) = @_;
        
        # reset
        $self->errstr(undef);
        
        if ($email eq 'a@a.com' and $password ne 'a') {
            $self->errstr('Wrong Username or Password');
            return;
        }
        
        my @contacts = ( {
            email => 'b@b.com',
            name => 'b',
        }, {
            email => 'c@c.com',
            name => 'c'
        } );
        return wantarray ? @contacts : \@contacts;
    }
    
    1;

We can use it within WWW::Contact

    my $wc = WWW::Contact->new();
    $wc->register_supplier( qr/\@a\.com$/, 'Unknown' );
    # or
    # $wc->register_supplier( 'a.com', 'Unknown' );
    
    my @contacts = $wc->get_contacts('a@a.com', 'b');
    my $errstr = $wc->errstr;

=head1 SEE ALSO

L<WWW::Mechanize>, L<Moose>

=head1 SUPPORTS

=over 4

=item Code trunk

L<http://github.com/fayland/perl-www-contact/tree/master>

=item Group

L<http://groups.google.com/group/perl-www-contact>

=back

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

Dimitar Petrov, C<< <mitakaa at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 *AUTHOR* all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
