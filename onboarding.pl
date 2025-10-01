#!/usr/bin/env perl
# ZChat Onboarding Interface
# Because sometimes the best way forward is to understand exactly what you're getting into

use v5.26.3;
use feature 'say';
use experimental 'signatures';
use strict;
use warnings;

use utf8;
use FindBin;
use lib "$FindBin::RealBin/lib";

use ZChat;
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

sub wait_for_user($prompt = "Press Enter to continue...") {
    print "$prompt ";
    <STDIN>;
}

sub check_dependencies() {
    print_header("ZChat Onboarding - Dependency Check");
    
    say "ZChat is written in Perl for performance and expressiveness.";
    say "Let's verify everything is working correctly.";
    say "";
    
    # Check Perl version
    my $perl_version = $^V;
    say "Perl version: $perl_version";
    if ($perl_version ge v5.26.3) {
        say "${success}OK: Perl version acceptable${rst}";
    } else {
        say "${error}ERROR: Perl 5.26.3+ required${rst}";
        exit 1;
    }
    say "";
    
    # Check core modules (required)
    say "Checking core modules:";
    my @core_modules = qw(Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard);
    my $core_good = 1;
    
    for my $mod (@core_modules) {
        if (eval "use $mod; 1") {
            say "${success}OK: $mod${rst}";
        } else {
            say "${error}ERROR: $mod${rst}";
            $core_good = 0;
        }
    }
    
    if (!$core_good) {
        say "";
        say "${error}Missing core modules detected. Please run the installation script first.${rst}";
        exit 1;
    }
    
    # Check optional modules
    say "";
    say "Checking optional modules:";
    my @optional_modules = qw(Image::Magick);
    my $optional_count = 0;
    
    for my $mod (@optional_modules) {
        if (eval "use $mod; 1") {
            say "${success}OK: $mod${rst}";
            $optional_count++;
        } else {
            say "${warning}WARNING: $mod (optional)${rst}";
        }
    }
    
    say "";
    say "${success}Core dependencies satisfied!${rst}";
    if ($optional_count > 0) {
        my $total_optional = scalar @optional_modules;
        say "${info}Optional modules available: $optional_count/$total_optional${rst}";
    } else {
        say "${warning}No optional modules available (image processing disabled)${rst}";
    }
    wait_for_user();
}

sub demonstrate_basic_usage() {
    print_header("Basic Usage Demonstration");
    
    print_section("Simple Query", 
        "The most basic usage is a simple query:\n" .
        "  z 'Hello, how are you?'\n\n" .
        "This will:\n" .
        "  • Use the 'default' session\n" .
        "  • Apply your system prompt\n" .
        "  • Store the conversation in history\n" .
        "  • Return the LLM's response"
    );
    
    print_section("Interactive Mode", 
        "For extended conversations, use interactive mode:\n" .
        "  z -i\n\n" .
        "This gives you a persistent chat session with:\n" .
        "  • Command history (up/down arrows)\n" .
        "  • Persistent conversation context\n" .
        "  • Easy exit with Ctrl+D or Ctrl+C"
    );
    
    wait_for_user();
}

sub demonstrate_session_management() {
    print_header("Session Management");
    
    print_section("What are Sessions?", 
        "Sessions are named conversation contexts that persist across runs.\n" .
        "They're perfect for organizing different projects or topics:\n\n" .
        "  z -n work/project1 'Design the API'\n" .
        "  z -n personal/learning 'Explain quantum computing'\n" .
        "  z -n debugging/auth 'Fix the login bug'\n\n" .
        "Each session maintains its own:\n" .
        "  • Conversation history\n" .
        "  • Pinned messages\n" .
        "  • System prompt settings"
    );
    
    print_section("Session Hierarchy", 
        "Sessions support hierarchical organization:\n\n" .
        "  z -n work/project1/api 'Design REST endpoints'\n" .
        "  z -n work/project1/frontend 'Build React components'\n" .
        "  z -n work/project1/docs 'Write API documentation'\n\n" .
        "This creates organized storage under:\n" .
        "  ~/.config/zchat/sessions/work/project1/api/\n" .
        "  ~/.config/zchat/sessions/work/project1/frontend/\n" .
        "  ~/.config/zchat/sessions/work/project1/docs/"
    );
    
    wait_for_user();
}

sub demonstrate_pin_system() {
    print_header("Pin System - The Secret Sauce");
    
    print_section("What are Pins?", 
        "Pins are persistent messages that get injected into every conversation.\n" .
        "They're perfect for:\n" .
        "  • Consistent behavior ('Be terse and precise')\n" .
        "  • Project context ('This is a Perl project')\n" .
        "  • Few-shot examples (user|||assistant pairs)\n" .
        "  • Current information (project status, requirements)"
    );
    
    print_section("Pin Types", 
        "System pins: Always included in system prompt\n" .
        "  z --pin-sys 'You are an expert Perl developer'\n\n" .
        "User pins: Individual user messages\n" .
        "  z --pin-user 'Assume all code is Perl'\n\n" .
        "Assistant pins: Individual assistant messages\n" .
        "  z --pin-ast 'I will provide code examples'\n\n" .
        "Paired examples: User|||assistant pairs\n" .
        "  z --pin-ua-pipe 'How to regex?|||Use \\\\d+ with anchors'"
    );
    
    print_section("Pin Modes", 
        "ZChat supports different ways to include pins:\n\n" .
        "concat (default): Traditional concatenation\n" .
        "  z --pin-mode-user concat --pin-user 'Rule 1' --pin-user 'Rule 2'\n\n" .
        "vars: Template variables in system prompt\n" .
        "  z --pin-mode-sys vars --system 'Base policy: <: \$pins_str :>'\n\n" .
        "varsfirst: Template processed once for first pin only\n" .
        "  z --pin-mode-user varsfirst --pin-tpl-user 'Reference: <: \$pins_str :>'"
    );
    
    wait_for_user();
}

sub demonstrate_configuration() {
    print_header("Configuration System");
    
    print_section("Precedence Chain", 
        "ZChat uses a sophisticated precedence system:\n\n" .
        "System Defaults → User Global → Environment → Shell Session → Session Specific → CLI\n\n" .
        "This means:\n" .
        "  • CLI flags override everything (temporary)\n" .
        "  • Session settings override user defaults\n" .
        "  • Shell settings override user defaults for this terminal\n" .
        "  • User settings override system defaults\n" .
        "  • System defaults provide sensible fallbacks"
    );
    
    print_section("Storage Scopes", 
        "Three storage scopes for different needs:\n\n" .
        "--store-user (-S): Global user preferences\n" .
        "  z --system-str 'Be helpful' --su\n\n" .
        "--store-pproc (--sp): Shell session settings\n" .
        "  z -n work/urgent --system-str 'Focus on critical issues' --sp\n\n" .
        "--store-session (--ss): Session-specific settings\n" .
        "  z -n project/api --system-file prompts/api.md --ss"
    );
    
    print_section("System Prompt Sources", 
        "Multiple ways to specify system prompts:\n\n" .
        "Files: --system-file path/to/prompt.md\n" .
        "Strings: --system-str 'You are a helpful assistant'\n" .
        "Personas: --system-persona helpful (requires persona tool)\n" .
        "Auto-resolve: --system name (tries file first, then persona)"
    );
    
    wait_for_user();
}

sub demonstrate_advanced_features() {
    print_header("Advanced Features");
    
    print_section("Streaming Responses", 
        "ZChat supports real-time streaming responses:\n" .
        "  • Immediate feedback as the LLM generates text\n" .
        "  • Automatic thought pattern removal for reasoning models\n" .
        "  • Configurable streaming behavior"
    );
    
    print_section("Multi-Modal Support", 
        "Image support via clipboard or files:\n" .
        "  z --clipboard 'What's in this image?'\n" .
        "  z --img photo.jpg 'Analyze this image'\n\n" .
        "Automatic detection of image vs text clipboard content\n" .
        "Cross-platform clipboard support (WSL2, Linux, macOS, Windows)"
    );
    
    print_section("Token Management", 
        "Built-in token counting and context management:\n" .
        "  z -T 'Count tokens in this text'\n" .
        "  z --tokens-full 'Detailed tokenization breakdown'\n" .
        "  z --ctx 'Show model context window size'"
    );
    
    print_section("History Management", 
        "Sophisticated conversation history handling:\n" .
        "  z --wipe 'Clear conversation history'\n" .
        "  z --wipeold 1.5h 'Remove messages older than 1.5 hours'\n" .
        "  z -E 'Edit history in your editor'\n" .
        "  z --conv-last - 'Output last message to stdout'"
    );
    
    wait_for_user();
}

sub demonstrate_programmatic_api() {
    print_header("Programmatic API");
    
    print_section("Perl API", 
        "ZChat provides a clean Perl API for integration:\n\n" .
        "use ZChat;\n" .
        "my \$z = ZChat->new(session => 'automated-reports');\n" .
        "\$z->pin('Generate executive summaries');\n" .
        "my \$response = \$z->query('Analyze this data');\n\n" .
        "Perfect for:\n" .
        "  • Automated report generation\n" .
        "  • Batch processing\n" .
        "  • Integration with other Perl tools"
    );
    
    print_section("Configuration Management", 
        "Programmatic configuration handling:\n\n" .
        "\$z->store_user_config({system_str => 'Be helpful'});\n" .
        "\$z->store_session_config({system_file => 'prompts/api.md'});\n" .
        "\$z->store_shell_config({session => 'work/urgent'});"
    );
    
    wait_for_user();
}

sub demonstrate_llm_integration() {
    print_header("LLM Integration");
    
    print_section("Supported Backends", 
        "ZChat works with multiple LLM backends:\n\n" .
        "llama.cpp: Local server (default)\n" .
        "  export LLAMA_URL=http://localhost:8080\n\n" .
        "Ollama: Local Ollama server\n" .
        "  export LLAMA_URL=http://localhost:11434\n\n" .
        "OpenAI: OpenAI API\n" .
        "  export OPENAI_BASE_URL=https://api.openai.com/v1\n" .
        "  export OPENAI_API_KEY=your-key-here\n\n" .
        "Any OpenAI-compatible API"
    );
    
    print_section("Model Information", 
        "Get model details and capabilities:\n" .
        "  z --metadata 'Show model metadata'\n" .
        "  z --ctx 'Show context window size'\n" .
        "  z --status 'Show current configuration'"
    );
    
    wait_for_user();
}

sub run_interactive_demo() {
    print_header("Interactive Demo");
    
    say "Let's try some ZChat features interactively!";
    say "";
    
    # Create a demo session
    my $z = ZChat->new(session => 'demo/onboarding');
    
    say "Created demo session: demo/onboarding";
    say "";
    
    # Add some pins
    $z->pin("You are demonstrating ZChat features", role => 'system', method => 'concat');
    $z->pin("This is a user pin for context", role => 'user', method => 'msg');
    $z->pin("I will provide helpful examples", role => 'assistant', method => 'msg');
    
    say "Added demonstration pins:";
    my $pins = $z->list_pins();
    for my $i (0..$#$pins) {
        my $pin = $pins->[$i];
        say "  $i: [$pin->{role}/$pin->{method}] $pin->{content}";
    }
    say "";
    
    say "Now let's try a query with these pins active:";
    say "Query: 'What is ZChat?'";
    say "";
    
    # This would normally make an actual LLM call
    say "In a real session, this would make an LLM request with:";
    say "  • System prompt with pinned system message";
    say "  • User pin as context";
    say "  • Assistant pin as example";
    say "  • Your query: 'What is ZChat?'";
    say "";
    
    say "The response would be streamed in real-time and stored in history.";
    say "";
    
    wait_for_user();
}

sub show_next_steps() {
    print_header("Next Steps");
    
    print_section("Documentation", 
        "Comprehensive documentation is available:\n\n" .
        "z --help              # Full CLI reference\n" .
        "z --help-cli          # Basic CLI usage\n" .
        "z --help-pins         # Pin system documentation\n" .
        "z --status            # Current configuration\n\n" .
        "README.md             # Project overview\n" .
        "PRECEDENCE.md         # Configuration system\n" .
        "help/cli.md           # CLI usage guide\n" .
        "help/pins.md          # Pin system guide"
    );
    
    print_section("Common Workflows", 
        "Here are some common usage patterns:\n\n" .
        "Project setup:\n" .
        "  z -n project/api --system-file prompts/api.md --ss\n" .
        "  z --pin-sys 'Focus on REST API design'\n" .
        "  z --pin-user 'Use modern Perl practices'\n\n" .
        "Shell session:\n" .
        "  z -n work/urgent --system-str 'Focus on critical issues' --sp\n" .
        "  z 'What should I prioritize?'\n\n" .
        "Interactive exploration:\n" .
        "  z -i\n" .
        "  >> Tell me about Perl's postderef feature\n" .
        "  >> Can you show an example?"
    );
    
    print_section("Getting Help", 
        "If you run into issues:\n\n" .
        "1. Check your LLM server is running and accessible\n" .
        "2. Verify environment variables are set correctly\n" .
        "3. Use z --status to see current configuration\n" .
        "4. Check the documentation files\n" .
        "5. Look at the examples in the refs/ directory"
    );
    
    say "";
    say "${success}You're ready to use ZChat!${rst}";
    say "";
    say "Remember: ZChat is designed for freedom and consistency.";
    say "You can work from whatever language you want, be it Bash, Python, Perl, or anything else.";
    say "";
    say "Happy chatting!";
}

# Main onboarding flow
sub main() {
    check_dependencies();
    demonstrate_basic_usage();
    demonstrate_session_management();
    demonstrate_pin_system();
    demonstrate_configuration();
    demonstrate_advanced_features();
    demonstrate_programmatic_api();
    demonstrate_llm_integration();
    run_interactive_demo();
    show_next_steps();
}

main() if __FILE__ eq $0;