package WWW::Contact;

use Class::MOP ();
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.09';
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
            'gmail.com'      => 'Gmail',
            'ymail.com'      => 'Yahoo',
            'rocketmail.com' => 'Yahoo',
            'rediffmail.com' => 'Rediffmail',
            'aol.com'        => 'AOL',
            
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
            'compaq.net'     => 'Hotmail',
            'hotmail.co.jp'  => 'Hotmail',
            'hotmail.co.uk'  => 'Hotmail',
            'hotmail.com'    => 'Hotmail',
            'hotmail.de'     => 'Hotmail',
            'hotmail.fr'     => 'Hotmail',
            'hotmail.it'     => 'Hotmail',
            'messengeruser.com' => 'Hotmail',
            'msn.com'        => 'Hotmail',
            'passport.com'   => 'Hotmail',
            'webtv.net'      => 'Hotmail',
        }
    }
);

sub get_contacts {
    my $self = shift;
    my ( $email, $password ) = @_;
    
    unless ( $email and $password ) {
        $self->errstr('Both email and password are required.');
        return;
    }
    
    unless ( $email =~ m/^(.+)\@(([^.]+)\.(.+))$/ ) {
        $self->errstr('You must supply full email address.');
        return;
    }
    
    my ( $username, $postfix ) = ( lc($1), lc($2) );
    
    # get supplier module
    my $supplier = $self->get_supplier_by_email($email);
    unless ($supplier) {
        $self->errstr("$email is not supported yet.");
        return;
    }
    
    my $module = 'WWW::Contact::' . $supplier;
    Class::MOP::load_class($module);
    my $wc = new $module;
    
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
    
    return;
}

sub register_supplier {
    my ($self, $pattern, $supplier) = @_;

    unshift @{ $self->supplier_pattern }, { pattern => $pattern, supplier => $supplier };
}

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact - Get contacts/addressbook from Web

=head1 SYNOPSIS

    use WWW::Contact;
    
    my $wc       = WWW::Contact->new();
    my @contacts = $wc->get_contacts('fayland@gmail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr; # like 'Wrong Password'
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

Get Contacts/AddressBook from public websites.

=head1 SUPPORTED EMAIL SUPPLIER

=over 4

=item Gmail

L<WWW::Contact::Gmail> By Fayland Lam

=item Yahoo! Mail

L<WWW::Contact::Yahoo> By Fayland Lam

=item Rediffmail

L<WWW::Contact::Rediffmail> By Sachin Sebastian

=item mail.163.com

L<WWW::Contact::CN::163> By Fayland Lam

=item AOL

L<WWW::Contact::AOL> By Fayland Lam

=item Mail

L<WWW::Contact::Mail> By Sachin Sebastian

=item Hotmail/Live Mail

L<WWW::Contact::Hotmail> By Fayland Lam

=back

=head1 METHODS

=head2 register_supplier

To use custom supplier, we must register within WWW::Contact

    $wc->register_supplier( qr/\@a\.com$/, 'Unknown' );
    $wc->register_supplier( 'a.com', 'Unknown' );

The first arg is a Regexp or domain from email postfix. The second arg is the according module postfix like 'Unknown' form WWW::Contact::Unknown

=head2 get_supplier_by_email

get supplier by email.

    my $supplier = $wc->get_supplier_by_email('a@gmail.com'); # 'Gmail'
    my $supplier = $wc->get_supplier_by_email('a@a.com');     # 'Unknown'

=head1 HOW TO WRITE YOUR OWN MODULE

please read L<WWW::Contact::Base> and examples: L<WWW::Contact::Yahoo> and L<WWW::Contact::Gmail>

Assuming we write a custom module as WWW::Contact::Unknown

    package WWW::Contact::Unknown;
    
    use Moose;
    extends 'WWW::Contact::Base';
    
    sub get_contacts {
        my ($self, $email, $password) = @_;
        
        # reset
        $self->errstr(undef);
        
        if ($email eq 'a@a.com' and $password ne 'a') {
            $self->errstr('Wrong Password');
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

    my $wc = new WWW::Contact;
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

L<http://code.google.com/p/perl-www-contact/>

=item Group

L<http://groups.google.com/group/perl-www-contact>

=back

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 *AUTHOR* all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
