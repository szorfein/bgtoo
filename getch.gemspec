require File.dirname(__FILE__) + '/lib/getch/version'

Gem::Specification.new do |s|
  s.name = 'getch'
  s.version = Getch::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'A CLI tool to install Gentoo or VoidLinux.'
  s.authors = ['szorfein']
  s.email = ['szorfein@protonmail.com']
  s.homepage = 'https://github.com/szorfein/getch'
  s.metadata = {
    'source_code_uri' => 'https://github.com/szorfein/getch',
    'changelog_uri' => 'https://github.com/szorfein/getch/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/szorfein/getch/issues',
    'wiki_uri' => 'https://github.com/szorfein/getch'
  }
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.5.0'

  s.files = Dir.glob('{assets,lib}/**/*', File::FNM_DOTMATCH)

  s.executables = [ 'getch' ]
  s.extra_rdoc_files = ['README.md']

  s.cert_chain  = ['certs/szorfein.pem']
  s.signing_key = File.expand_path('~/.ssh/gem-private_key.pem') if $0 =~ /gem\z/
end
