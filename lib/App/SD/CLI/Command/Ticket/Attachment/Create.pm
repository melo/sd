package App::SD::CLI::Command::Ticket::Attachment::Create;
use Any::Moose;
extends 'App::SD::CLI::Command::Attachment::Create';

__PACKAGE__->register_arg_translations( f => 'file' );

# override args to feed in that ticket's uuid as an argument to the comment
before run => sub {
    my $self = shift;
    $self->require_uuid;

    $self->set_prop(ticket => $self->uuid);
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

