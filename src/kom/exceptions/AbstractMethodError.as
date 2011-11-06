/**
 * @fileOverview kom.exceptions.AbstractMethodError
 * @author komelgman@yandex.ru
 */

package kom.exceptions {
	import flash.errors.IllegalOperationError;

	public class AbstractMethodError extends IllegalOperationError {	  
		public function AbstractMethodError(message: * = "Attempt to call an abstract method", id: * = 0) {
			super(message,  id);
		}   
	}
}