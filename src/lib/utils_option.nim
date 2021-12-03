import std/options
import fp/maybe

proc convertMaybe*[T](x: Option[T]): Maybe[T] =
  if x.isSome():
    just(x.unsafeGet())
  else:
    nothing(T)

proc convertMaybe*[T](x: Maybe[T]): Option[T] =
  if maybe.isDefined(x):
    some(x.get())
  else:
    none(T)
