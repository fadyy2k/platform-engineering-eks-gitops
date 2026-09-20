package main

import "testing"

func TestVersionHasDefault(t *testing.T) {
	if version == "" {
		t.Fatal("version must not be empty")
	}
}
