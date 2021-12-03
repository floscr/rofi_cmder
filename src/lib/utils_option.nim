import std/options
import fp/option

proc convertOption*[T](x: option.Option[T]): options.Option[T] =
  if x.isDefined():
    options.some(x.get())
  else:
    options.none(T)

proc convertOption*[T](x: options.Option[T]): option.Option[T] =
  if x.isSome():
    option.some(x.unsafeGet())
  else:
    option.none(T)
