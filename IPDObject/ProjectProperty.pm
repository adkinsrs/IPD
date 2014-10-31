package IPD::IPDObject::ProjectProperty;

=head1 NAME 

IPD::IPDObject::ProjectProperty - Module for managing attributes of ProjectProperty-type IPD objects

=cut

use IPD::Client;
use strict;
use warnings;
use base qw(IPD::IPDObject);

our $AUTOLOAD;

my $extension = "";

my $attributes = {
	'id' => -1,
	'project_id' => -1,
	'type' => -1,
	'value' => -1,
	'created_at' => -1,
	'updated_at' => -1
};

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new( %args );
    bless($self, $class);
    return $self;
}

sub AUTOLOAD {
    my ($self, $value) = @_;
    my ($oper, $attr) = ($AUTOLOAD =~ /(get_|set_)(\w+)$/);
    return if( $AUTOLOAD =~ /DESTROY/ );

    unless ($oper && $attr) {
	die "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n";
    }
    unless (exists ${$attributes}{$attr}) {
	die "No such attribute '$attr' exists for the class " . ref($self) . "\n";
    }

    no strict 'refs';
    # adds $AUTOLOAD name to symbol table for quicker repeated calls to same function
    if ($oper eq 'get_') {	
#	*{$AUTOLOAD} = sub { shift->{$attr} };
    } elsif ($oper eq 'set_') {
#	*{$AUTOLOAD} = sub { shift->{$attr} = shift };
        $self->{$attr} = $value;	# if we want to 'set' the new value
    }
    use strict 'refs';

    return $self->{$attr};
}

#Methods we do not want to access with AUTOLOAD
sub set_id {
    my $self = shift;
    my $value = shift;
    die ("Not allowed to change the ID: $!\n") if (defined $self -> {'id'});
    $self -> {'id'} = $value;
}

sub set_type {
    my $self = shift;
    my $value = shift;
    die ("Not allowed to change the type: $!\n") if (defined $self->{'type'});
    $self->{'type'} = $value;
}

#Class and instance methods using this class

=item IPD::IPDObject::ProjectProperty->get_project_property($id)

B<Description:> Retrieves project property information from a single project property ID from IPD and stores into an object
B<Parameters:> The ID of the project property to be queried.
B<Returns:> An IPD::IPDObject::ProjectProperty object

=cut

sub get_project_property {
    my $class = shift;
    die ("Must call 'get' methods in the form of ", ref($class), "->method() : $!\n") if ref $class;
    my $id = shift;

    $extension = "project_properties/$id.xml";
    my $elem = $class->SUPER::XML2Object(IPD::Net->send_request(IPD::Client->get_client, $extension, "GET"));
    my $sp = $class->new(%{$elem});
    return $sp;
}

=item IPD::IPDObject::ProjectProperty->get_project_properties_by_project($id)

B<Description:> Retrieves all project property information associated with a single project ID from IPD and stores into an array of objects
B<Parameters:> The ID of the project to be queried.
B<Returns:> An array of IPD::IPDObject::ProjectProperty objects

=cut

sub get_project_properties_by_project {
    my $class = shift;
    die ("Must call 'get' methods in the form of ", ref($class), "->method() : $!\n") if ref $class;
    my $id = shift;
    my @selves;
    my @sp;

    $extension = "projects/$id.xml";
    my $elem = $class->SUPER::XML2Object(IPD::Net->send_request(IPD::Client->get_client, $extension, "GET"));
    if (ref($elem->{'project_properties'}->{'project_property'}) eq 'HASH') {
	push @sp, $elem->{'project_properties'}->{'project_property'}->{'id'};
    } else {
    	foreach my $prop ( @{$elem->{'project_properties'}->{'project_property'}} ) {
	    push @sp, $prop->{'id'};
        }
    }
    foreach my $sp_id (@sp) {
	push @selves, $class->get_project_property($sp_id);
    }
    return \@selves;
}

=item $obj->create_project_property()

B<Description:> Creates a new Project Property entry in IPD based on the provided ProjectProperty object
B<Parameters:> An IPD::IPDObject::ProjectProperty object
B<Returns:> The same IPD::IPDObject::ProjectProperty object

=cut

sub create_project_property {
    my $self = shift;
    die ("Must call 'create|save|delete' methods in the form of ", '$object->method()', " : $!\n") unless ref $self;

    foreach my $name ('project_id', 'type', 'value') {
	if (!exists(${$self}{$name})) {
	    die "ERROR:  project_id, type, and value elements are required. $!\n";	
	}
    }
    $extension = "project_properties.xml";
    my $xml =  ref($self)->SUPER::construct_xml($self, "project_property");
    my $temp = ref($self)->SUPER::XML2Object(IPD::Net->send_request(IPD::Client->get_client, $extension, "POST", $xml));
    my $id = $temp->{'id'};
    $extension = "project_properties/$id.xml";
    my $elem = ref($self)->SUPER::XML2Object(IPD::Net->send_request(IPD::Client->get_client, $extension, "GET"));
    $self = ref($self)->new(%{$elem});
    return $self;
}

=item $obj->save_project_property()

B<Description:> Updates a Project Property entry in IPD based on the provided ProjectProperty object.  The object must have an 'id' attribute associated with an existing project property in IPD
B<Parameters:> An IPD::IPDObject::ProjectProperty object
B<Returns:> The same IPD::IPDObject::ProjectProperty object

=cut

sub save_project_property {
    my $self = shift;
    die ("Must call 'create|save|delete' methods in the form of ", '$object->method()', " : $!\n") unless ref $self;
    my $id;

    exists $self->{'id'} ? $id = $self->{'id'} : die "No Project Property ID present.  Perhaps you wanted to use 'create_project_property' method? $!\n";
    $extension = "project_properties/$id.xml";
    my $xml =  ref($self)->SUPER::construct_xml($self, "project_property");
    IPD::Net->send_request(IPD::Client->get_client, $extension, "PUT", $xml);
    my $elem = ref($self)->SUPER::XML2Object(IPD::Net->send_request(IPD::Client->get_client, $extension, "GET"));
    $self =ref($self)->new(%{$elem});
    return $self;
}

=item $obj->delete_project_property()

B<Description:> Deletes a Project Property entry from IPD, based on the ID attribute found in the ProjectProperty object.  Also clears all attributes from the object.
B<Parameters:> An IPD::IPDObject::ProjectProperty object
B<Returns:> Nothing

=cut

sub delete_project_property {
    my $self = shift;
    die ("Must call 'create|save|delete' methods in the form of ", '$object->method()', " : $!\n") unless ref $self;

    die "No Project Property ID attribute present for delete command: $!\n" if (! exists $self->{'id'});
    my $id = $self->{'id'};
    $extension = "project_properties/$id.xml";
    IPD::Net->send_request(IPD::Client->get_client, $extension, "DELETE");
    $self = ();
    return;
}


1;
