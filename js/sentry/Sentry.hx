package sentry;

@:jsRequire('@sentry/browser')
extern class Sentry{
    public static function init(param:{dsn:String}):Void;
}