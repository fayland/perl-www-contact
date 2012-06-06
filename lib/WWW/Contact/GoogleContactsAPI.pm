package WWW::Contact::GoogleContactsAPI;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.44';
our $AUTHORITY = 'cpan:FAYLAND';

has 'skip_NoEmail' => ( is => 'ro', isa => 'Bool', default => 1 );
has authsub => (
    is => 'ro',
    isa => 'Net::Google::AuthSub',
    lazy => 1,
    default => sub {
        require Net::Google::AuthSub;
        Net::Google::AuthSub->new(service => 'cp');
    },
);

has 'json' =>
	(
		is => 'ro',
	    isa => 'JSON::XS',
	 	lazy => 1,
    	default => sub
		{
        	require JSON::XS;
        	return JSON::XS->new->utf8;
		}
	);

# Authenticate with $email and $password and return either an array
# of contacts or a reference to an array, according to context

sub get_contacts {
    my ($self, $email, $password) = @_;

    $self->errstr(undef);				# Reset

    my $resp = $self->authsub->login($email, $password);
    unless ($resp && $resp->is_success)
	{
        $self->errstr("Wrong Username or Password");
        return;
    }
	my $url = "https://www.google.com/m8/feeds/contacts/default/full"
		. "?max-results=9999&alt=json";
	$url .= "&v=3.0";					# Gives more fields
    $self->get($url, $self->authsub->auth_params)
	or return;
    my $content = $self->ua->content;
    my $data = $self->json->decode($content);
	$data = $data->{feed} if ($data);

    my @contacts;
	@contacts = map $self->make_contact($_), @{$data->{entry}}
		if ($data);

    @contacts = grep { exists $_->{email} } @contacts
        if $self->skip_NoEmail;

    return wantarray ? @contacts : \@contacts;
}

# Return an entry from Google as a reference to a hash in our format.
# Feyland's 0.23 only returned "name" and "email" fields, we return
# everything.

sub make_contact {
	my ($self, $in) = @_;

	my %orig = %$in;
	my $out = {};
	my $name;
	if (my $n = delete $in->{'gd$name'}) {
		$name = $n->{'gd$fullName'}->{'$t'};
		$out->{name} = $name;		# Backward compatible
		for ($n->{'gd$familyName'}->{'$t'})
		{
			$out->{family_name} = $_ if ($_);
		}
		for ($n->{'gd$givenName'}->{'$t'})
		{
			$out->{given_name} = $_ if ($_);
		}
	}

        my @links;
        local $_ = delete $in->{link}
                and @links = @$_;

        foreach (@links)
        {
                if ($_->{type} eq 'image/*' && exists $_->{'gd$etag'}) {
                        (my $href = $_->{href}) =~ s/\?v=3\.0//;
                        $out->{photo}{href} = $href;
                        $out->{photo}{content} = sub { $self->ua->get($href, $self->authsub->auth_params)->decoded_content() };
                }
        }

	# $out->{emails} = [[ADDRESS, TYPE], ...]
	my @emails;
	local $_ = delete $in->{'gd$email'}
		and @emails = @$_;
	foreach (@emails)
	{
		($_->{rel} || "") =~ /#(.*)/;
		$_ = [$_->{address}, $1];
	}
	if (@emails)
	{
		$out->{emails} = \@emails;
		# Derive single-value field for backward compatibility
		($out->{email}) = $emails[0][0];
	}

	$_ = delete $in->{'gContact$nickname'}
		and $_ = $_->{'$t'}
		and $out->{nickname} = $_;

	# $out->{addresses} = [[TYPE => ADDRESS], ...]
	my @ads;
        my @postal_ads;
	$_ = delete $in->{'gd$structuredPostalAddress'}
		and @ads = @$_;
	foreach (@ads)
	{
                my $address;
                ($address->{street1}, $address->{street2}) = split /\n/, delete $_->{'gd$street'}{'$t'};
                $address->{postal_code} = delete $_->{'gd$postcode'}{'$t'};
                $address->{city} = delete $_->{'gd$city'}{'$t'};
                $address->{state} = delete $_->{'gd$region'}{'$t'};
                $address->{country} = delete $_->{'gd$country'}{'$t'};

		my ($type) = (delete $_->{rel}) =~ /#(.*)/;
		$_ = (delete $_->{'gd$formattedAddress'})->{'$t'};
		s/\s+$//g; s/\n/, /g;
		$_ = [$_, $type];
                push @postal_ads, $address;
	}
	$out->{addresses} = \@ads if (@ads);
        $out->{postal_addresses} = \@postal_ads if (@postal_ads);

	my @events;
	$_ = delete $in->{'gContact$event'}
		and @events = @$_;
	foreach (@events)
	{
		my $type = $_->{rel};
		$_ = $_->{'gd$when'}
			and $_ = $_->{startTime}
			and $_ = [$_, $type];
	}
	@events = grep $_, @events;
	$out->{events} = \@events if (@events);

	$_ = delete $in->{'gContact$birthday'}
		and $_ = $_->{when}
		and $out->{birthday} = $_
		and $_ = _age($_)
		and $out->{age} = $_;

	my @ims;
	$_ = delete $in->{'gd$im'}
		and @ims = @$_;
	foreach (@ims)
	{
		delete $_->{label};				# Always "None"
		delete $_->{type};				# Nearly always "other"
		my $p = delete $_->{protocol};
		if ($p &&= $p ne "None" && lc $p)
		{
			$p =~ s/.*#//; $p =~ s/google_/g/;
		}
		$_ = [$p || "?" => $_->{address}];
	}
	$out->{instant_messengers} = \@ims if (@ims);

	my @phones;
	$_ = delete $in->{'gd$phoneNumber'}
		and @phones = @$_;
	foreach (@phones)
	{
		my ($type) = (delete $_->{rel} || "") =~ /#(.*)/;
		my $t = delete $_->{'$t'};
		$t =~ s/(^\s+|\s+$)//isg;
		$_ = [$t, $type];
	}
	$out->{phones} = \@phones
		if (@phones);

	# Google doesn't seem to keep a creation date
	$out->{updated} = (delete $in->{updated})->{'$t'};

	$_ = delete $in->{content}
		and $_ = $_->{'$t'}
		and $out->{notes} = $_;

	# Map "Custom" fields.  "Label" = key, "Custom value" = value
	my @u;
	$_ = delete $in->{'gContact$userDefinedField'}
		# List of hash refs, {key => ..., value => ...}
		and @u = @$_;
	foreach (@u) { $out->{$_->{key}} = $_->{value} }

	$_ = delete $in->{'gContact$relation'};
	if ($_)
	{
		foreach (@$_)
		{
			my $k = $_->{rel};
			push @{$out->{$k}}, $_->{'$t'};
		}
	}

	my @orgs;
	$_ = delete $in->{'gd$organization'}
		and @orgs = @$_;
	foreach (@orgs)
	{
		my ($type) = (delete $_->{rel} || "") =~ /#(.*)/;
		$_ = [$_->{'gd$orgName'}->{'$t'}, $type];
	}
	@orgs = grep $_->[0], @orgs;		# Zap null orgs
	$out->{organisations} = \@orgs if (@orgs);

	my @urls;
	$_ = delete $in->{'gContact$website'}
		and @urls = @$_;
	foreach (@urls)
	{
		$_ = {$_->{rel} => $_->{href}};
	}
	$out->{urls} = \@urls if (@urls);

	my @groups;
	$_ = delete $in->{'gContact$groupMembershipInfo'}
		and @groups = @$_;
	@groups = map $self->group_name($_), @groups;
	$out->{groups} = \@groups if (@groups);

	# Ignore id link app$edited gd$etag category title

	return $out;
}

# Return a list containing the name of a group given
# its URL or () if unknown, e.g. "My Contacts"

{ # statics
	my %name;							# Map known URLs to group names
sub group_name {
	my ($self, $g) = @_;

	my $url = $g->{href};

	unless (exists $name{$url})
	{
		$_ = eval { $self->get("$url?alt=json", $self->authsub->auth_params) };
		$self->errstr(undef);
		if ($_)
		{
			$_ = $self->ua->content;
			$_ = $self->json->decode($_);
			$_ = $_->{entry}{content}{'$t'};
		}
		$name{$url} = $_;
	}
	return $name{$url} || ();
}
}

# Given birth date YYYY-MM-DD, return the age in years
sub _age {
	my ($dob) = @_;

	my ($by, $bm, $bd) = split /-/, $dob;
	return undef unless ($by && $bm && $bd);

	my @now = localtime;
	my ($y, $m, $d) = (1900 + $now[5], 1 + $now[4], $now[3]);
	# Decrement age if hasn't had birthday yet this year
	my $age = $y - $by - ($m < $bm || $m == $bm && $d < $bd ? 1 : 0);

	return $age;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

WWW::Contact::GoogleContactsAPI - Get contacts via Google Contacts Data API

=head1 SYNOPSIS

    use WWW::Contact;
    use Data::Dumper;

    my $wc = WWW::Contact->new();
    my @contacts = $wc->get_contacts('itsa@gmail.com', 'password');
    my $errstr   = $wc->errstr;
    die $errstr if ($errstr);
    print Dumper(\@contacts);

=head1 DESCRIPTION

WWW::Contact::GoogleContactsAPI uses the Google Contacts Data API
(L<http://code.google.com/apis/contacts/docs/3.0/reference.html>)
to retrieve all a user's contacts.

=head1 METHODS

=over 4

=item C<< $wc->get_contacts($email, $password) >>

Login to Google using C<email> and C<password>.  Fetch all the given
user's contacts.  Return them as a list or, in a scalar context, as a
reference to a list.  Each element of the result represents one
contact as a reference to a hash with one or more of the following
keys (all fields are optional):

=over 4

=item C<name>

The contact's main name as a single string.  This may
be a person's full name or the name of an organisation.

=item C<family_name>

A person's family name (surname or last name),
usually shared with one or both parents.

=item C<given_name>

A person's given name (christian name or first name).

=item C<nickname>

An alternative name or alias for the contact.

=item C<emails>

An ordered list of references to pairs, C<< [$address, $type] >>,
where C<$type> is C<"home">, C<"work">, C<"other"> or some custom
label and C<$address> is the corresponding e-mail address.

=item C<email>

The first address in C<emails>, if any.
Deprecated: use C<< $contact->{emails}->[0][0] >>.

=item C<addresses>

As for C<emails> but C<$address> is a
postal addresses, given as a single string.

=item C<birthday>

The date of birth in the form C<YYYY-MM-DD> or C<--MM-DD>.

=item C<age>

The age in years today, calculated from the date of birth.

=item C<events>

An ordered list of references to pairs, C<[$date, $type]>, where
C<$date> is the date of the event in the form C<YYYY-MM-DD> and
C<$type> is the type of event, e.g. "anniversary".

=item C<instant_messengers>

An ordered list of references to pairs, C<[$protocol,
$address]>, where C<$protocol> is one of C<gtalk>,
C<jabber>, C<msn>, C<skype>, C<yahoo> and possibly others.

=item C<phones>

An ordered list of references to pairs, C<[$number, $type]>, where
C<$type> is one of C<home>, C<work>, C<mobile> and possibly other
values.  C<$number> may include punctuation and comments.

=item C<updated>

The time when this contact was last modified in the
form C<YYYY-MM-DDTHH:MM:SS.SSSZ> where C<T> is a
literal "T", C<SS.SSS> is seconds and milliseconds
as a decimal and C<Z> indicates the UTC time-zone.

=item C<notes>

Arbitrary text.

=item C<child>, C<spouse>, etc.

Relations are returned as references to
lists of names (even mother and father).

=item C<organisations>

An ordered list of reference to pairs, C<[$organisation,
$type]>, where C<$organisation> is a body this contact is
associated with and C<$type> is the type of relationship.

=item C<groups>

A reference to a list of group names

=item C<>

=item Custom fields

Any custom fields not recognised by the module are
returned in the output hash with a simple string value.

=back

=back

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Mechanize>, L<Net::Google::AuthSub>

=head1 AUTHORS

Fayland Lam, C<< <fayland at gmail.com> >>
Denis Howe, C<< denis.howe=gc@gmail.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
