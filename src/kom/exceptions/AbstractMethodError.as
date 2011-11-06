/**
 * @fileOverview kom.exceptions.AbstractMethodError
 * @author komelgman@yandex.ru
 */

package kom.exceptions {
	import flash.errors.IllegalOperationError;

	public class AbstractMethodError extends IllegalOperationError {	  
		public function AbstractMethodError() {
			super("Attempt to call an abstract method");
		}   
	}
}