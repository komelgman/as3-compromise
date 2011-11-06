/**
 * @fileOverview kom.exceptions..RequiredValueError
 * @author komelgman@yandex.ru
 */

package kom.exceptions {
    import flash.errors.IllegalOperationError;

    public class RequiredValueError extends IllegalOperationError {
		public function RequiredValueError(message : * = "Required value not set", id : * = 0) {
			super(message, id);
		}
    }
}
