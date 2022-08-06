package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"regexp"
)

type User struct {
	CurrentlyLoggedIn bool
	SteamID           string
	Name              string
	LoginCount        int
	LogoutCount       int
}

var (
	users map[string]User
)

func init() {
	users = make(map[string]User)
}

func main() {

	// curl -fLo v_rising.stdout.0 https://nomad.justmiles.net/v1/client/fs/cat/c9ac0fd6-0eba-7501-56c4-04cd65577202\?path\=alloc%2Flogs%2Fv_rising.stdout.0
	file, err := os.Open("v_rising.stdout.0")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		var user User

		// Check for login session
		re := regexp.MustCompile(`BeginAuthSession for SteamID: (?P<id>[0-9]+)`)
		if re.MatchString(line) {
			matches := re.FindStringSubmatch(line)
			id := matches[re.SubexpIndex("id")]

			user = getUser(id)
			user.CurrentlyLoggedIn = true
			user.LoginCount++
		}

		// Check for logout
		re = regexp.MustCompile(`SteamPlatformSystem - EndAuthSession platformId: (?P<id>[0-9]+)`)
		if re.MatchString(line) {
			matches := re.FindStringSubmatch(line)
			id := matches[re.SubexpIndex("id")]

			user = getUser(id)
			user.CurrentlyLoggedIn = false
			user.LogoutCount++
		}

		// Get Character name
		re = regexp.MustCompile(`User .* '(?P<id>[0-9]+)'.*Character: '(?P<name>[^']*)'`)
		if re.MatchString(line) {
			matches := re.FindStringSubmatch(line)
			id := matches[re.SubexpIndex("id")]
			name := matches[re.SubexpIndex("name")]

			user = getUser(id)
			user.Name = name
		}

		// update user list
		users[user.SteamID] = user
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
	for id, user := range users {
		if user.Name == "" {
			continue
		}
		fmt.Println(id, user.CurrentlyLoggedIn, user.Name, user.LoginCount, user.LogoutCount)
	}
}

func getUser(id string) User {

	// Return the current user if it exists
	if u, ok := users[id]; ok {
		return u
	}

	// create a new user
	return User{
		SteamID: id,
	}

}
