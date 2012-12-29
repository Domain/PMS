module main;

import std.stdio;

import net.pms.PMS;

int main(string[] args)
{
	bool displayProfileChooser = false;
	bool headless = true;

	if (args.length > 0) {
		for (int a = 0; a < args.length; a++) {
			if (args[a].opEquals(CONSOLE)) {
				System.setProperty(CONSOLE, Boolean.toString(true));
			} else if (args[a].opEquals(NATIVELOOK)) {
				System.setProperty(NATIVELOOK, Boolean.toString(true));
			} else if (args[a].opEquals(SCROLLBARS)) {
				System.setProperty(SCROLLBARS, Boolean.toString(true));
			} else if (args[a].opEquals(NOCONSOLE)) {
				System.setProperty(NOCONSOLE, Boolean.toString(true));
			} else if (args[a].opEquals(PROFILES)) {
				displayProfileChooser = true;
			}
		}
	}

	try {
		Toolkit.getDefaultToolkit();

		if (GraphicsEnvironment.isHeadless()) {
			if (System.getProperty(NOCONSOLE) is null) {
				System.setProperty(CONSOLE, Boolean.toString(true));
			}
		} else {
			headless = false;
		}
	} catch (Throwable t) {
		System.err.println("Toolkit error: " ~ t.getClass().getName() ~ ": " ~ t.getMessage());

		if (System.getProperty(NOCONSOLE) is null) {
			System.setProperty(CONSOLE, Boolean.toString(true));
		}
	}

	if (!headless && displayProfileChooser) {
		ProfileChooser.display();
	}

	try {
		setConfiguration(new PmsConfiguration());

		assert(getConfiguration() !is null);

		// Load the (optional) logback config file. This has to be called after 'new PmsConfiguration'
		// as the logging starts immediately and some filters need the PmsConfiguration.
		LoggingConfigFileLoader.load();

		// create the PMS instance returned by get()
		createInstance(); 
	} catch (Throwable t) {
		String errorMessage = String.format(
											"Configuration error: %s: %s",
											t.getClass().getName(),
											t.getMessage()
											);

		System.err.println(errorMessage);

		if (!headless && instance !is null) {
			JOptionPane.showMessageDialog(
										  (cast(JFrame) (SwingUtilities.getWindowAncestor(cast(Component) instance.getFrame()))),
										  errorMessage,
										  Messages.getString("PMS.42"),
										  JOptionPane.ERROR_MESSAGE
										  );
		}
	}

	return 0;
}
