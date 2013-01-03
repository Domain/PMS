module main;

import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.exception;
import std.array;
import std.regex;
import std.algorithm;

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

void j2d(string filename, string jdir, string ddir)
{
	auto rpath = relativePath(filename, jdir);
	auto dname = ddir ~ rpath;

	if (!dirName(dname).exists)
		dirName(dname).mkdirRecurse();

	if (filename.extension() != ".java")
	{
		copy(filename, dname);
		return;
	}

	auto src = File(filename, "r");
	scope(exit) src.close;
	auto content = appender!string();
	foreach (line; src.byLine(KeepTerminator.yes))
	{
		auto newLine = line;
		if (newLine.startsWith("package "))
		{
			newLine = newLine.replace("package ", "module ");
			newLine = newLine.replace(";", "." ~ baseName(filename, ".java") ~ ";");
		}
		newLine = newLine.replace(" extends ", " : ");
		newLine = newLine.replace(" implements ", " : ");
		newLine = newLine.replace("@Override", "override");
		newLine = newLine.replace("== null", "is null");
		newLine = newLine.replace("!= null", "!is null");
		newLine = newLine.replace("boolean", "bool");
		newLine = newLine.replace("@Deprecated", "deprecated");
		newLine = newLine.replace(".debug(", ".debug_(");
		content.put(newLine);
	}

	auto text = content.data;

	auto ctorR = regex(r"(\s*)(public|private|protected)(\s+)[_a-zA-Z][_a-zA-Z0-9]*(\s*)\(", "g");
	text = std.regex.replace(text, ctorR, "$1$2$3this$4(");

	auto throwR = regex(r"(\)[ \t\n]*)throws[ \t\n]+[_a-zA-Z][_a-zA-Z0-9]*[ \t\n]*(,[ \t\n]*[_a-zA-Z][_a-zA-Z0-9]*[ \t\n]*)*\{", "g");
	text = std.regex.replace(text, throwR, "$1{");

	auto subClassR = regex(r"new\s+([_a-zA-Z][_a-zA-Z0-9]*)\s*(\([^\)]*\))\s*\{", "g");
	text = std.regex.replace(text, subClassR, "new class$2 $1 {");

	auto hashR = regex(r"\bint\b(\s*)hashCode(\s*\()", "g");
	text = std.regex.replace(text, hashR, "override hash_t$1toHash$2");

	auto equalsR = regex(r"\bbool\b(\s*)equals(\s*\()", "g");
	text = std.regex.replace(text, equalsR, "override equals_t$1opEquals$2");

	auto instanceofR = regex(r"([\(,|&=])\s*([_a-zA-Z][\._a-zA-Z0-9\(\)]*)\s+instanceof\s+([_a-zA-Z][_a-zA-Z0-9]*)(\s*[),|&?])", "g");
	text = std.regex.replace(text, instanceofR, "$1 cast($3)$2 !is null $4");

	auto castR = regex(r"([\(,|&=])\s*(\(\s*(?:byte|short|int|long|float|double|[_a-zA-Z][_a-zA-Z0-9]*(?:\.[_a-zA-Z][_a-zA-Z0-9]*)?)\s*(?:\[\s*\]\s*)?\))(\s*[_a-zA-Z])", "g");
	text = std.regex.replace(text, castR, "$1 cast$2$3");

	auto outerR = regex(r"\b[_a-zA-Z][_a-zA-Z0-9]*\.this\b", "g");
	text = std.regex.replace(text, outerR, "this.outer");

	auto arrayR = regex(r"new\s+([_a-zA-Z][\._a-zA-Z0-9]*\s*\[\s*\])\s*\{([^\}]*)\}", "g");
	text = std.regex.replace(text, arrayR, "cast($1)[$2]");

	dname = dname.replace(".java", ".d");
	std.file.write(dname, text);

	return;
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

	if (!jdir.endsWith(dirSeparator))
		jdir ~= dirSeparator;

	if (!ddir.endsWith(dirSeparator))
		ddir ~= dirSeparator;

	foreach (entry; dirEntries(jdir, SpanMode.depth)) 
	{ 
		if (entry.isFile())
		{
			writeln("processing " ~ entry.name ~ " ...");
			j2d(entry.name, jdir, ddir);
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
