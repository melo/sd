#!/usr/bin/env perl
package App::SD::CLI::Dispatcher;
use Prophet::CLI::Dispatcher -base;
use Moose;

on qr'^\?(.*)$' => sub {my $cmd = $1 || '';  run ('help'. $cmd,  @_); last_rule;};

# 'sd about' -> 'sd help about', 'sd copying' -> 'sd help copying'
on qr'^(about|copying)$' => sub { run('help '.$1, @_); last_rule;};
on qr'^help (?:push|pull|publish|server)$' => sub { run('help sync', @_); last_rule;};
on qr'^help (?:env)$' => sub { run('help environment', @_); last_rule;};
on qr'^help (?:ticket)$' => sub { run('help tickets', @_); last_rule;};
on qr'^help ticket (list|search|find)$' => sub { run('help search', @_); last_rule;};
on qr'^help (?:list|find)$' => sub { run('help search', @_); last_rule;};

on qr{ticket \s+ give \s+ (.*) \s+ (.*)}xi => sub {
    my $self = shift;
    $self->context->set_arg(type => 'ticket');
    $self->context->set_arg(id => $1);
    $self->context->set_arg(owner => $2);
    run('update', $self, @_);
};

# allow type to be specified via primary commands, e.g.
# 'sd ticket display --id 14' -> 'sd display --type ticket --id 14'
on qr{^(ticket|comment|attachment) \s+ (.*)}xi => sub {
    my $self = shift;
    $self->context->set_arg(type => $1);
    run($2, $self, @_);
};

#on qr'^about$' => sub { run('help about'); last_rule;};


# Run class based commands
on qr{.} => sub {
    my $self = shift;
    my $cli = $self->cli;

    my @possible_classes;

    # we want to dispatch on the original command "ticket attachment create"
    # AND on the command we received "create"
    for ([@{ $self->dispatching_on }], [split ' ', $_]) {
        my @pieces = __PACKAGE__->resolve_builtin_aliases(@$_);

        while (@pieces) {
            push @possible_classes, "App::SD::CLI::Command::" . join '::', @pieces;
            shift @pieces;
        }
    }

    for my $class (@possible_classes) {
        if ($cli->_try_to_load_cmd_class($class)) {
            return $class->run;
        }
    }

    # found no class-based rule
    next_rule;
};

__PACKAGE__->dispatcher->add_rule(
    Path::Dispatcher::Rule::Dispatch->new(
        dispatcher => Prophet::CLI::Dispatcher->dispatcher,
    ),
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

