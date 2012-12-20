module net.pms.update.UpdateException;

public class UpdateException : Exception {
	private static const long serialVersionUID = 661674274433241720L;

	this(String message) {
		super(message);
	}

	this(String message, Throwable cause) {
		super(message, cause);
	}
}
