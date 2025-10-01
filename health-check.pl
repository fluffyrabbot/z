#!/usr/bin/env perl
# ZChat Health Check
# Because sometimes the best way forward is to verify everything is working correctly

use v5.26.3;
use feature 'say';
use experimental 'signatures';
use strict;
use warnings;

use utf8;
use FindBin;
use lib "$FindBin::RealBin/lib";

use ZChat::Utils ':all';
use ZChat::ansi;

# Colors matching the author's style
my $header = a24bg(0,50,100) . a24fg(255,255,255);
my $success = a24fg(144,238,144) . $aa_bo;
my $warning = a24fg(255,210,64) . $aa_bo;
my $error = a24fg(255,158,158) . $aa_boit;
my $info = a24fg(100,200,255) . $aa_bo;

sub print_header($title) {
    say "$header$title$rst";
    say "";
}

sub print_section($title, $content) {
    say "$info$title$rst";
    say $content;
    say "";
}

sub check_perl_version() {
    print_section("Perl Version", "");
    
    my $perl_version = $^V;
    say "Perl version: $perl_version";
    
    if ($perl_version ge v5.26.3) {
        say "$successOK: Perl version acceptable$rst";
        return 1;
    } else {
        say "$errorERROR: Perl 5.26.3+ required$rst";
        return 0;
    }
}

sub check_dependencies() {
    print_section("Dependencies", "");
    
    my @modules = qw(Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Image::Magick Clipboard);
    my $all_good = 1;
    
    for my $mod (@modules) {
        if (eval "use $mod; 1") {
            say "$successOK: $mod$rst";
        } else {
            say "$errorERROR: $mod$rst";
            $all_good = 0;
        }
    }
    
    return $all_good;
}

sub check_configuration() {
    print_section("Configuration", "");
    
    my $config_dir = "$ENV{HOME}/.config/zchat";
    if (-d $config_dir) {
        say "$successOK: Config directory exists$rst";
        say "  Location: $config_dir";
    } else {
        say "$errorERROR: Config directory missing$rst";
        say "  Expected: $config_dir";
        return 0;
    }
    
    # Check user config
    my $user_config = "$config_dir/user.yaml";
    if (-f $user_config) {
        say "$successOK: User config exists$rst";
        say "  Location: $user_config";
    } else {
        say "$warningWARNING: User config missing$rst";
        say "  Expected: $user_config";
    }
    
    # Check system directory
    my $system_dir = "$config_dir/system";
    if (-d $system_dir) {
        say "$successOK: System directory exists$rst";
        say "  Location: $system_dir";
    } else {
        say "$warningWARNING: System directory missing$rst";
        say "  Expected: $system_dir";
    }
    
    # Check sessions directory
    my $sessions_dir = "$config_dir/sessions";
    if (-d $sessions_dir) {
        say "$successOK: Sessions directory exists$rst";
        say "  Location: $sessions_dir";
    } else {
        say "$warningWARNING: Sessions directory missing$rst";
        say "  Expected: $sessions_dir";
    }
    
    return 1;
}

sub check_llm_connection() {
    print_section("LLM Connection", "");
    
    # Check environment variables
    my @env_vars = qw(LLAMA_URL LLAMA_API_URL LLAMACPP_SERVER LLAMA_CPP_SERVER LLM_API_URL OPENAI_BASE_URL OPENAI_API_BASE OPENAI_URL);
    my $found_env = 0;
    
    for my $var (@env_vars) {
        if (defined $ENV{$var}) {
            say "$successOK: Environment variable $var set$rst";
            say "  Value: $ENV{$var}";
            $found_env = 1;
        }
    }
    
    if (!$found_env) {
        say "$warningWARNING: No LLM environment variables found$rst";
        say "  Default will be used: http://127.0.0.1:8080";
    }
    
    # Try to test connection
    say "";
    say "Testing ZChat status...";
    my $status_output = `./z --status 2>&1`;
    my $status_exit = $?;
    
    if ($status_exit == 0) {
        say "$successOK: ZChat status command successful$rst";
    } else {
        say "$errorERROR: ZChat status command failed$rst";
        say "  Exit code: $status_exit";
        say "  Output: $status_output";
    }
    
    return $status_exit == 0;
}

sub check_executable_permissions() {
    print_section("Executable Permissions", "");
    
    my @executables = qw(z install.sh onboarding.pl health-check.pl);
    my $all_good = 1;
    
    for my $file (@executables) {
        if (-f $file) {
            if (-x $file) {
                say "$successOK: $file is executable$rst";
            } else {
                say "$errorERROR: $file is not executable$rst";
                $all_good = 0;
            }
        } else {
            say "$errorERROR: $file not found$rst";
            $all_good = 0;
        }
    }
    
    return $all_good;
}

sub show_recommendations() {
    print_section("Recommendations", "");
    
    say "If you encountered any issues:";
    say "";
    say "1. Run the installation script: ./install.sh";
    say "2. Check your LLM server is running and accessible";
    say "3. Verify environment variables are set correctly";
    say "4. Use z --status to see current configuration";
    say "5. Run the onboarding script: ./onboarding.pl";
    say "";
    say "For more help, see:";
    say "  README.md - Project overview";
    say "  QUICKSTART.md - Quick start guide";
    say "  help/cli.md - CLI usage guide";
    say "  help/pins.md - Pin system guide";
}

sub main() {
    print_header("ZChat Health Check");
    
    my $perl_ok = check_perl_version();
    my $deps_ok = check_dependencies();
    my $config_ok = check_configuration();
    my $llm_ok = check_llm_connection();
    my $perms_ok = check_executable_permissions();
    
    say "";
    print_header("Summary");
    
    if ($perl_ok && $deps_ok && $config_ok && $llm_ok && $perms_ok) {
        say "$successAll checks passed! ZChat is ready to use.$rst";
    } else {
        say "$errorSome issues detected. Please address them before using ZChat.$rst";
        show_recommendations();
    }
}

main() if __FILE__ eq $0;