/**
 * @fileOverview kom.deferred.Deferred (Standard implementation of the interface IDeferred)
 * @author komelgman@yandex.ru
 *
 * https://github.com/komelgman/Compromise
 *
 * License:: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package kom.deferred {
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    import kom.exceptions.TimeoutError;

    public class Deferred implements IPromise, IDeferred {

        private static const CANCEL : String = '__cancel';

        private var _promise : Promise = null;

        public function Deferred(canceller : Function = null) {
            _promise = new Promise(this);

            if (null != canceller) {
                _promise.custom(CANCEL, canceller);
            }
        }

        public static function isDeferred(obj : Object) : Boolean {
            return obj is IDeferred;
        }

        public static function isPromise(obj : Object) : Boolean {
            return obj is IPromise;
        }


        /**
         * `wait` returns promise (IPromise) that will be called after `sec` elapsed
         * with real elapsed time (msec)
         *
         * @example
         * <listing version="3.0">
         *   Deferred.wait(1).done(function (elapsed) {
         *       log(elapsed); //=> may be 990-1100
         *   });
         * </listing>
         *
         */
        public static function wait(secs: Number) : IPromise {
            var deferred : Deferred = new Deferred(function () : void { clearTimeout(timer); }),
                startTime : Date = new Date();

            var timer : uint = setTimeout(function () : void {
                deferred.resolve((new Date).getTime() - startTime.getTime());
            }, secs * 1000);

            return deferred.promise;
        }


        /**
         * `async` function is for calling function asynchronous.
         */
        public static function async(func : Function, ...args) : IPromise {
            var deferred : Deferred = new Deferred(function () : void {
                clearTimeout(timer);
            });

            var timer : uint = setTimeout(function () : void {
                deferred.resolve(func.apply(this, args));
            }, 0);

            return deferred.promise;
        }


        /**
         * `parallel` wraps up `deferredlist` to one deferred.
         * This is useful when some asynchronous resources are required.
         *
         * `deferredlist` can be Array or Object (Hash). If you specify
         * multiple objects as arguments, then they are wrapped into
         * an Array.
         *
         * @example
         * <listing version="3.0">
         *   Deferred.parallel([
         *       $.get("foo.html"),
         *       $.get("bar.html")
         *   ]).done(function (values) {
         *       values[0] //=> foo.html data
         *       values[1] //=> bar.html data
         *   });
         *
         *   Deferred.parallel({
         *       foo: $.get("foo.html"),
         *       bar: $.get("bar.html")
         *   }).done(function (values) {
         *       values.foo //=> foo.html data
         *       values.bar //=> bar.html data
         *   });
         * </listing>
         */
        public static function parallel(...deferredList) : IPromise {
            return batchProcess('parallel', deferredList);
        }

        /**
         * Continue process when one deferred in `deferredlist` has completed. Others will be canceled.
         * parallel ('and' processing) <=> earlier ('or' processing)
         */
        public static function earlier(...deferredList) : IPromise {
            return batchProcess('earlier', deferredList);
        }


        /**
         * Construct chain with array and return its Promise.
         * This is shorthand for construct Promise chains.
         *
         * @example
         * <listing version="3.0">
         * Deferred
         *     .chain(1, // initialise value
         *         test, // test(1) => 2
         *         Deferred.wait(10), // wait 10 second, no changes with value
         *         test, // test(2) => 4
         *         test  // test(4) => 8
         *     ).done(function(output : *) : void {
         *         log(output); // output = 8
         *     });
         *
         * function test(x : int) : int {
         *     return x * 2;
         * }
         * </listing>
         */
        public static function chain(input : *, ...deferredList) : IPromise {
            var result : Deferred = new Deferred(function() : void { stop = true; process.cancel(); }),
                stop : Boolean = false,
                index : int = 0, length : int = deferredList.length,
                process : IPromise = Deferred.async(_chain,  input);

            return result.promise;

            function _chain(data : *) : void {
                if (index == length) {
                    result.resolve(data);
                }

                var obj : * = deferredList[index];

                if (obj is Function) {
                    Deferred.async(obj, data).then(_resolve, result.reject);
                } else if (Deferred.isPromise(obj)) {
                    obj.then(function() : void { index++; _chain(data);}, result.reject);
                } else if (Deferred.isDeferred(obj)) {
                    obj.done(_resolve).resolve(data);
                } else if ((obj is Object) || (obj is Array)) {
                    Deferred.parallel(obj).then(_resolve, result.reject);
                } else {
                    result.reject(new Error("unknown type in process chains"));
                }

                function _resolve(value : *) : void {
                    index++;
                    _chain(value);
                }
            }
        }


        internal function fireFinalEvent(reason : String, data : * = null) : void {
            _promise.notifyAll(reason,  data, true);
        }

        internal function fireIntermediateEvent(reason : String, data : * = null) : void {
            _promise.notifyAll(reason,  data, false);
        }



        /**
         * implementation of interface IDeferred methods
         */

        public function resolve(data : * = null) : void {
            fireFinalEvent(AbstractPromise.SUCCESS, data);
        }

        public function reject(data : * = null) : void {
            fireFinalEvent(AbstractPromise.ERROR, data);
        }

        public function update(data : * = null) : void {
            fireIntermediateEvent(AbstractPromise.PROGRESS, data);
        }

        public function cancel() : void {
            fireFinalEvent(CANCEL);
        }

        public function get promise() : IPromise {
            return _promise;
        }

        /**
         * implementation of interface IPromise methods
         */

        public function then(callback : Function = null, errorback : Function = null) : IPromise {
            return _promise.then(callback, errorback);
        }

        public function done(callback : Function) : IPromise {
            return _promise.done(callback);
        }

        public function fail(errorback : Function) : IPromise {
            return _promise.fail(errorback);
        }

        public function progress(progress : Function) : IPromise {
            return _promise.progress(progress);
        }

        public function always(callback : Function) : IPromise {
            return _promise.always(callback);
        }

        public function custom(reason : String, callback : Function) : IPromise {
            return _promise.custom(reason,  callback);
        }

        public function timeout(secs : Number) : IPromise {
            always(function () : void { clearTimeout(timer); });

            var timer : uint = setTimeout(function () : void {
                reject(new TimeoutError());
            }, secs * 1000);

            return this;
        }

        /**
         * Processing the deferredList for one of two strategies (parallel or earlier)
         */
        private static function batchProcess(processName : String,  deferredList : *) : IPromise {
            if ((deferredList.length == 1) && ((deferredList[0] is Object) || (deferredList[0] is Array))) {
                deferredList = deferredList[0];
            }

            var process : Function = (processName == 'parallel') ? processParallel : processEarlier,
                deferred : Deferred = new Deferred(),
                num : int = 0,
                result : Object = {};

            for (var i : * in deferredList) {
                if (!deferredList.hasOwnProperty(i)) {
                    continue;
                }

                var obj : * = deferredList[i];

                if (obj is Function) {
                    obj = deferredList[i] = Deferred.async(obj);
                } else if (Deferred.isDeferred(obj)) {
                    obj = deferredList[i] = obj.promise;
                } else if (Deferred.isPromise(obj)) {
                    // nothing
                } else if ((obj is Object) || (obj is Array)) {
                    obj = deferredList[i] = Deferred.parallel(obj);
                } else {
                    deferred.reject(new Error("unknown type"));
                }

                deferred.custom(CANCEL, obj.cancel);
                process(obj, i);
            }

            if (!num) {
                Deferred.async(function () : void {
                    deferred.resolve(result);
                });
            }

            return deferred.promise;

            function processParallel(d : IPromise, i : *) : void {
                num++;
                d.then(
                    function (v : *) : void {
                        result[i] = v;

                        if (--num <= 0) {
                            deferred.resolve(result);
                        }
                    },
                    deferred.reject
                );
            }

            function processEarlier(d : IPromise, i : *) : void {
                num++;
                d.then(function (v : *) : void {
                        result[i] = v;

                        stopOther(i);

                        deferred.resolve(result);
                    },
                    deferred.reject
                );
            }

            function stopOther(i : *) : void {
                for (var j : * in deferredList) {
                    if (!deferredList.hasOwnProperty(i) || (i == j)) {
                        continue;
                    }

                    deferredList[j].cancel();
                }
            }
        }
    }
}


/**
 * Internal implementation of the AbstractPromise
 */

import flash.utils.Dictionary;
import kom.deferred.AbstractPromise;

import kom.deferred.Deferred;
import kom.deferred.IPromise;

class Promise extends AbstractPromise {
    private var waiting : Dictionary = new Dictionary();
    private var deferred : Deferred = null;
    private var finished : Boolean = false;

    private var value : * = null;
    private var reason : String = '';

    public function Promise(deferred : Deferred) {
        this.deferred = deferred;
    }

    public override function custom(reason : String, callback : Function) : IPromise {
        if (null == callback) {
            return this;
        }

        if (finished) {
            Deferred.async(callback, (reason == AbstractPromise.ALWAYS) ? {reason : this.reason, value : value} : value);
        } else {
            addListener(reason, {callback : callback});
        }

        return this;
    }

    public override function cancel() : void {
        deferred.cancel();
    }

    public override function timeout(secs : Number) : IPromise {
        return (deferred.timeout(secs) as Deferred).promise;
    }

    internal function notifyAll(reason : String, data : *, finish : Boolean = true) : void {
        if(finished) {
            throw new Error("This deferred has already been resolved");
        }

        this.finished = finish;
        this.reason = reason;
        this.value = data;

        _notifyAll(reason, data);
        _notifyAll(AbstractPromise.ALWAYS, {reason : reason,  value : data});

        function _notifyAll(reason : String, value : *) : void {
            for (var i : int = 0, listeners : Array = getListeners(reason), n : int = listeners.length; i < n; ++i) {
                Deferred.async(listeners[i].callback, value);
            }
        }
    }

    private function addListener(reason : String,  listener : Object) : void {
        if (!(reason in waiting)) {
            waiting[reason] = new Array();
        }

        waiting[reason].push(listener);
    }

    private function getListeners(reason : String) : Array {
        return waiting[reason] || new Array();
    }
}