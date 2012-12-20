module main;

import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.exception;
import std.array;
import std.regex;

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

string j2d(string filename)
{
	return null;
}

string[] test()
{
	return ["abc"];
}

int main(string[] argv)
{
	if (argv.length != 3)
	{
		writefln("Usage: %s <javadir> <ddir>", argv[0]);
		return 1;
	}

	auto jdir = argv[1];
	auto ddir = argv[2];
	auto t = test();

	foreach (entry; dirEntries(jdir, SpanMode.depth)) 
	{ 
		if (entry.isFile())
		{
			auto src = File(entry.name, "r");
			scope(exit) src.close;
			auto content = appender!string();
			foreach (line; src.byLine())
			{
				line = line.replace("@Deprecated", "deprecated");
				line = line.replace("@Override", "override");
				line = line.replace("Boolean", "bool");
				content.put(line);
			}
		}
	}

	foreach (entry; dirEntries(ddir, SpanMode.depth)) 
	{ 
		if (entry.isDir())
		{
			generateFile(entry.name, ddir);
		}
	}
	return 0;
}
