/**
 * @fileOverview kom.exceptions.TimeoutError
 * @author komelgman@yandex.ru
 */

package kom.exceptions {
    public class TimeoutError extends Error {
        public function TimeoutError() {
            super('operation timed out');
        }
    }
}
