package main

import "fmt"

type warning struct{ error }

func isWarning(err error) bool {
	_, is := err.(warning)
	return is
}

func warn(mess string, args ...interface{}) error {
	return warning{fmt.Errorf(mess, args...)}
}
