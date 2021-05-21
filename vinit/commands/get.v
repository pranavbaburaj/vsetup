module commands

import os { create, execute, is_dir, join_path, mkdir, vmodules_dir, getwd, is_file, read_file }
import exception { VinitException }

struct ModulesDependency {
	mut:
	v_module_filename string
	vinit_dependency_filename string
}

struct Dependencies {
	filename string

	mut:
	dependencies map[string]string
}

fn dependency_file_parser(mod ModulesDependency) ?Dependencies {
	mut dependencies := Dependencies{filename:mod.vinit_dependency_filename}
	file_content := read_file(dependencies.filename) or {
		VinitException{
			exception_message : err.msg,
			fatal : true
		}.raise()
		return dependencies
	}
	file_content_lines := file_content.split_into_lines()
	mut line_count := 1
	for line in file_content_lines {
		statement := line.split(' ')
		if statement.len < 2 {
			VinitException{
				exception_message : 'Expected two parameters, but got ${statement.len}',
				exception_suggestion : 'line number $line_count in $',
				fatal : true
			}.raise()
			return dependencies
		}
		name, url := statement[0], statement[1]
		dependencies.dependencies[name] = url
	}
	return dependencies
}

fn (mut mod ModulesDependency) add_modules_dependency() int {
	path := join_path(getwd(), 'vinit.get')
	if !is_file(join_path(getwd(), 'v.mod')) {
		return 1
	}
	if !is_file(path) {
		_ := create(path) or {
			VinitException{
				exception_message : err.msg,
				fatal : true
			}.raise()
			return 1
		}
	}

	mod.v_module_filename = join_path(getwd(), 'v.mod')
	mod.vinit_dependency_filename = path
	println(dependency_file_parser(mod))
	return 0
}

struct CloneRepository {
	// The url from which the source of the package
	url  string
	// The name of the directory to store the package in
	name string
}

fn (repo CloneRepository) install() {
	// execute('git clone $repo.url ${join_path(vmodules_dir(), repo.name)}')
	ModulesDependency{}.add_modules_dependency()
}

fn check_if_module_exists(module_name string) bool {
	if !is_dir(vmodules_dir()) {
		mkdir(vmodules_dir()) or {
			panic(err)
			return false
		}
		return false
	}
	return is_dir(join_path(vmodules_dir(), module_name))
}

pub fn get() int {
	parameters := prompt_user(['url', 'name'], '[?]')
	name, url := parameters['name'], parameters['url']
	if check_if_module_exists(name) {
		println('[INSTALLED] $name seams to be already installed')
	} else {
		CloneRepository{
			url: url
			name: name
		}.install()
	}
	return 0
}
