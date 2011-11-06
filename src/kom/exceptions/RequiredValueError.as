/**
 * @fileOverview kom.exceptions..RequiredValueError
 * @author komelgman@yandex.ru
 */

package kom.exceptions {
    import flash.errors.IllegalOperationError;

    public class RequiredValueError extends IllegalOperationError {
		public function RequiredValueError() {
			super("Required value not set");
		}
    }
}
