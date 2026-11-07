.PHONY: release lint test bench-load clean

release:
	ruby usr/bin/release.rb

lint:
	bundle exec rubocop
	bundle exec rbs validate

test: lint
	bundle exec polyrun parallel-rspec --workers 5 --merge-failures

bench-load:
	env -u BUNDLE_PATH bundle exec ruby benchmarks/load.rb

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
