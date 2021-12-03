import std/options
import std/sugar
import fp/option

proc fpOptionToStdOption[T](x: option.Option[T]): options.Option[T] =
  x.fold(
    () => options.none(T),
    (x) => options.some(x)
  )
