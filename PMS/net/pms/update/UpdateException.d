module net.pms.update.UpdateException;

public class UpdateException : Exception {
	private static final long serialVersionUID = 661674274433241720L;

	UpdateException(String message) {
		super(message);
	}

	UpdateException(String message, Throwable cause) {
		super(message, cause);
	}
}
