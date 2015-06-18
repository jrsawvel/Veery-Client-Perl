package App::Dispatch;

use strict;
use warnings;
use diagnostics;

use App::Modules;
use App::Function;

my %cgi_params = Function::get_cgi_params_from_path_info("function", "one", "two", "three", "four");


my $dispatch_for = {
    showerror          =>   sub { return \&do_sub(       "Function",       "do_invalid_function"      ) },
    post               =>   sub { return \&do_sub(       "ShowPost",       "show_post"                ) },
    searchform         =>   sub { return \&do_sub(       "ShowStream",     "show_search_form"         ) },
    stream             =>   sub { return \&do_sub(       "ShowStream",     "show_stream"              ) },
    tag                =>   sub { return \&do_sub(       "ShowStream",     "tag_search"               ) },
    search             =>   sub { return \&do_sub(       "ShowStream",     "string_search"            ) },
    login              =>   sub { return \&do_sub(       "User",           "show_login_form"          ) },
    dologin            =>   sub { return \&do_sub(       "User",           "do_login"                 ) },
    nopwdlogin         =>   sub { return \&do_sub(       "User",           "no_password_login"        ) },
    createpost         =>   sub { return \&do_sub(       "CreatePost",     "create_post"              ) },
    compose            =>   sub { return \&do_sub(       "Compose",        "show_new_post_form"       ) },
    logout             =>   sub { return \&do_sub(       "User",           "logout"                   ) },
    delete             =>   sub { return \&do_sub(       "ChangeStatus",   "delete_post"              ) },
    deleted            =>   sub { return \&do_sub(       "ShowStream",     "show_deleted_posts"       ) },
    undelete           =>   sub { return \&do_sub(       "ChangeStatus",   "undelete_post"            ) },
    edit               =>   sub { return \&do_sub(       "EditPost",       "show_post_to_edit"        ) },
    updatepost         =>   sub { return \&do_sub(       "EditPost",       "update_post"              ) },
    splitscreen        =>   sub { return \&do_sub(       "Compose",        "show_splitscreen_form"    ) },
    splitscreenedit    =>   sub { return \&do_sub(       "EditPost",       "splitscreen_edit"         ) }, 
    settings           =>   sub { return \&do_sub(       "Settings",       "get_user_settings"        ) }, 
    updatesettings     =>   sub { return \&do_sub(       "Settings",       "update_settings"          ) }, 
    rss                =>   sub { return \&do_sub(       "ShowStream",     "create_rss"               ) }, 
    cacheit            =>   sub { return \&do_sub(       "CacheHtml",      "cacheit"                  ) }, 
};

sub execute {
    my $function = $cgi_params{function};

    $dispatch_for->{stream}->() if !defined($function) or !$function;

    $dispatch_for->{post}->($function) unless exists $dispatch_for->{$function} ;

    defined $dispatch_for->{$function}->();
}

sub do_sub {
    my $module = shift;
    my $subroutine = shift;
    eval "require App::$module" or Page->report_error("user", "Runtime Error (1):", $@);
    my %hash = %cgi_params;
    my $coderef = "$module\:\:$subroutine(\\%hash)"  or Page->report_error("user", "Runtime Error (2):", $@);
    eval "{ &$coderef };" or Page->report_error("user", "Runtime Error (2):", $@) ;
}

1;
