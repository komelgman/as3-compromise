/**
 * @fileOverview kom.exceptions.TimeoutError
 * @author komelgman@yandex.ru
 */

package kom.exceptions {
    public class TimeoutError extends Error {
        public function TimeoutError(message : * = 'operation timed out', id : * = 0) {
            super(message, id);
        }
    }
}
