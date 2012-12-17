module main;

import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.exception;
import std.array;

void generateFile(string dir, string prefix)
{
	enforce(dir.isDir());
	chdir(dir);
	auto path = relativePath(dir, prefix);
	path = path.replace("\\", ".");
	auto files = appender!string();
	foreach (entry; dirEntries(dir, SpanMode.shallow)) 
	{ 
		if (entry.isFile() && entry.name.extension() == ".d")
		{
			auto filename = baseName(entry.name, ".d");

			if (filename != "all")
				files.put("public import " ~ path ~ "." ~ filename ~";\n");
		}
	}
	if (files.data != "")
	{
		auto f = File("all.d", "w");
		f.writeln("module " ~ path ~ ".all;\n");
		f.write(files.data);
		f.close();
	}
}

int main(string[] argv)
{
	if (argv.length != 2 && argv.length != 3)
	{
		writefln("Usage: %s <dir> [-r]", argv[0]);
		return 1;
	}

	auto dir = argv[1];
	auto r = false;
	if (argv.length == 3 && argv[2] == "-r")
	{
		r = true;
	}

	foreach (entry; dirEntries(dir, SpanMode.depth)) 
	{ 
		if (entry.isDir())
		{
			generateFile(entry.name, dir);
		}
	}
	return 0;
}
