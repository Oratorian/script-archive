#!/bin/bash

# Emby server configuration
EMBY_SERVER="http://localhost:8096"
API_KEY=""
SERVER_ID=""

# Settings
LINK_TITLES=false # true or false (true= links gets generated, false= no links are generated)
IMAGE_SIZE=250  # Set the default image width in pixels, height gets adjusted automaticly via css, 250 is a good middle value

# Function to display a progress bar
show_progress() {
    local duration=$1
    local increment=$((duration / 20))
    local elapsed=0

    while [ $elapsed -lt $duration ]; do
        elapsed=$((elapsed + increment))
        local progress=$((elapsed * 100 / duration))
        local filled=$((progress / 5))
        local empty=$((20 - filled))

        printf "\r["
        for i in $(seq 1 $filled); do printf "#"; done
        for i in $(seq 1 $empty); do printf " "; done
        printf "] $progress%%"

        sleep $increment
    done

    printf "\r[####################] 100%%\n"
}

# Function to check and install jq and curl if not installed
check_and_install_dependencies() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        if command -v apt-get &> /dev/null; then
            (sudo apt-get update -y &> /dev/null && sudo apt-get install -y jq &> /dev/null) &
            show_progress 30
        elif command -v yum &> /dev/null; then
            (sudo yum install -y epel-release &> /dev/null && sudo yum install -y jq &> /dev/null) &
            show_progress 30
        elif command -v brew &> /dev/null; then
            (brew install jq &> /dev/null) &
            show_progress 30
        else
            echo "Error: Package manager not found. Please install jq manually."
            exit 1
        fi
        echo "jq installed successfully."
    else
        echo "jq is already installed."
    fi

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing curl..."
        if command -v apt-get &> /dev/null; then
            (sudo apt-get update -y &> /dev/null && sudo apt-get install -y curl &> /dev/null) &
            show_progress 30
        elif command -v yum &> /dev/null; then
            (sudo yum install -y curl &> /dev/null) &
            show_progress 30
        elif command -v brew &> /dev/null; then
            (brew install curl &> /dev/null) &
            show_progress 30
        else
            echo "Error: Package manager not found. Please install curl manually."
            exit 1
        fi
        echo "curl installed successfully."
    else
        echo "curl is already installed."
    fi
}

# Function to get all TV shows
get_tv_shows() {
    curl -s -H 'accept: application/json' -X GET "${EMBY_SERVER}/emby/Items?Recursive=true&IncludeItemTypes=Series&api_key=${API_KEY}" | jq -r '.Items[] | "\(.Name) \(.Id) \(.ImageTags.Primary)"'
}

# Function to get all movies
get_movies() {
    curl -s -H 'accept: application/json' -X GET "${EMBY_SERVER}/emby/Items?Recursive=true&IncludeItemTypes=Movie&api_key=${API_KEY}" | jq -r '.Items[] | "\(.Name) \(.Id) \(.ImageTags.Primary)"'
}

# Function to get seasons and episodes count for a TV show
get_seasons_and_episodes() {
    local show_id=$1
    local seasons=$(curl -s -H 'accept: application/json' -X GET "${EMBY_SERVER}/emby/Shows/${show_id}/Seasons?api_key=${API_KEY}")
    local season_count=$(echo "$seasons" | jq '.Items | length')
    local episodes_per_season=$(echo "$seasons" | jq -r '.Items[] | .Id' | xargs -I {} curl -s -H 'accept: application/json' -X GET "${EMBY_SERVER}/emby/Shows/${show_id}/Episodes?SeasonId={}&api_key=${API_KEY}" | jq -r '.Items | length' | awk '{s+=$1} END {print s}')
    echo "$season_count $episodes_per_season"
}

# Function to create an HTML page with the list of TV shows and movies and their images
create_html_page() {
    local tv_shows="$1"
    local movies="$2"

    mkdir -p img  # Create the img directory if it doesn't exist

    cat <<EOL > media.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Available Media</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .menu { margin-bottom: 20px; }
        .menu button { margin-right: 10px; padding: 10px; cursor: pointer; }
        .search-bar { margin-bottom: 20px; }
        .search-bar input { padding: 10px; width: 100%; box-sizing: border-box; }
        .shows, .movies { display: flex; flex-wrap: wrap; }
        .show, .movie { flex: 1 1 23%; display: flex; flex-direction: column; align-items: center; margin-bottom: 20px; padding: 10px; box-sizing: border-box; margin-right: 1%; }
        .show img, .movie img { width: ${IMAGE_SIZE}px; height: auto; border: 1px solid #ddd; border-radius: 5px; }
        .show a, .movie a { text-decoration: none; color: #333; text-align: center; }
        .show a:hover, .movie a:hover { text-decoration: underline; }
        .show-title, .movie-title { width: 100%; color: #333; padding: 5px; box-sizing: border-box; text-align: center; font-weight: bold; min-height: 50px; display: flex; align-items: center; justify-content: center; }
        .table-view { display: none; width: 100%; border-collapse: collapse; }
        .table-view th, .table-view td { border: 1px solid #ddd; padding: 10px; text-align: left; }
    </style>
    <script>
        function switchView(view) {
            document.querySelector('.shows').style.display = view === 'tv_shows' ? 'flex' : 'none';
            document.querySelector('.movies').style.display = view === 'movies' ? 'flex' : 'none';
            document.querySelector('.table-view').style.display = view === 'table' ? 'table' : 'none';
        }

        function searchShows() {
            const input = document.getElementById('search-input');
            const filter = input.value.toLowerCase();
            const showDivs = document.querySelectorAll('.show');
            const movieDivs = document.querySelectorAll('.movie');
            const tableRows = document.querySelectorAll('.table-view tbody tr');

            showDivs.forEach(show => {
                const title = show.querySelector('.show-title').textContent;
                if (title.toLowerCase().includes(filter)) {
                    show.style.display = '';
                } else {
                    show.style.display = 'none';
                }
            });

            movieDivs.forEach(movie => {
                const title = movie.querySelector('.movie-title').textContent;
                if (title.toLowerCase().includes(filter)) {
                    movie.style.display = '';
                } else {
                    movie.style.display = 'none';
                }
            });

            tableRows.forEach(row => {
                const title = row.querySelector('td a, td').textContent;
                if (title.toLowerCase().includes(filter)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }
    </script>
</head>
<body>
    <h1>Available Media</h1>
    <div class="menu">
        <button onclick="switchView('tv_shows')">TV Shows</button>
        <button onclick="switchView('movies')">Movies</button>
        <button onclick="switchView('table')">Table View</button>
    </div>
    <div class="search-bar">
        <input type="text" id="search-input" onkeyup="searchShows()" placeholder="Search for TV shows or movies...">
    </div>
    <div class="shows list-view">
EOL

    # Add TV shows to the HTML
    while IFS= read -r line; do
        show_name=$(echo "$line" | cut -d ' ' -f1-$(($(echo "$line" | wc -w) - 2)))
        show_id=$(echo "$line" | awk '{print $(NF-1)}')
        image_tag=$(echo "$line" | awk '{print $NF}')
        img_url="${EMBY_SERVER}/Items/${show_id}/Images/Primary?tag=${image_tag}&api_key=${API_KEY}"
        img_path="img/${show_id}.jpg"
        item_url="${EMBY_SERVER}/item?id=${show_id}&serverId=${SERVER_ID}"

        # Download the image if it doesn't exist
        if [ ! -f "$img_path" ]; then
            curl -s -o "$img_path" "$img_url"
        fi

        if [ "$LINK_TITLES" = true ]; then
            echo "        <div class=\"show\">" >> media.html
            echo "            <div class=\"show-title\"><a href=\"$item_url\">$show_name</a></div>" >> media.html
            echo "            <a href=\"$item_url\"><img src=\"$img_path\" alt=\"$show_name\"></a>" >> media.html
            echo "        </div>" >> media.html
        else
            echo "        <div class=\"show\">" >> media.html
            echo "            <div class=\"show-title\">$show_name</div>" >> media.html
            echo "            <img src=\"$img_path\" alt=\"$show_name\">" >> media.html
            echo "        </div>" >> media.html
        fi
    done <<< "$tv_shows"

    cat <<EOL >> media.html
    </div>
    <div class="movies list-view" style="display: none;">
EOL

    # Add movies to the HTML
    while IFS= read -r line; do
        movie_name=$(echo "$line" | cut -d ' ' -f1-$(($(echo "$line" | wc -w) - 2)))
        movie_id=$(echo "$line" | awk '{print $(NF-1)}')
        image_tag=$(echo "$line" | awk '{print $NF}')
        img_url="${EMBY_SERVER}/Items/${movie_id}/Images/Primary?tag=${image_tag}&api_key=${API_KEY}"
        img_path="img/${movie_id}.jpg"
        item_url="${EMBY_SERVER}/item?id=${movie_id}&serverId=${SERVER_ID}"

        # Download the image if it doesn't exist
        if [ ! -f "$img_path" ]; then
            curl -s -o "$img_path" "$img_url"
        fi

        if [ "$LINK_TITLES" = true ]; then
            echo "        <div class=\"movie\">" >> media.html
            echo "            <div class=\"movie-title\"><a href=\"$item_url\">$movie_name</a></div>" >> media.html
            echo "            <a href=\"$item_url\"><img src=\"$img_path\" alt=\"$movie_name\"></a>" >> media.html
            echo "        </div>" >> media.html
        else
            echo "        <div class=\"movie\">" >> media.html
            echo "            <div class=\"movie-title\">$movie_name</div>" >> media.html
            echo "            <img src=\"$img_path\" alt=\"$movie_name\">" >> media.html
            echo "        </div>" >> media.html
        fi
    done <<< "$movies"

    cat <<EOL >> media.html
    </div>
    <table class="table-view">
        <thead>
            <tr>
                <th>Title</th>
                <th>Type</th>
                <th>Seasons</th>
                <th>Episodes</th>
                <th>Image</th>
            </tr>
        </thead>
        <tbody>
EOL

    # Add TV shows and movies to the table view
    while IFS= read -r line; do
        show_name=$(echo "$line" | cut -d ' ' -f1-$(($(echo "$line" | wc -w) - 2)))
        show_id=$(echo "$line" | awk '{print $(NF-1)}')
        img_path="img/${show_id}.jpg"
        item_url="${EMBY_SERVER}/item?id=${show_id}&serverId=${SERVER_ID}"
        seasons_and_episodes=$(get_seasons_and_episodes "$show_id")
        seasons=$(echo "$seasons_and_episodes" | awk '{print $1}')
        episodes=$(echo "$seasons_and_episodes" | awk '{print $2}')

        if [ "$LINK_TITLES" = true ]; then
            echo "            <tr>" >> media.html
            echo "                <td><a href=\"$item_url\">$show_name</a></td>" >> media.html
        else
            echo "            <tr>" >> media.html
            echo "                <td>$show_name</td>" >> media.html
        fi
        echo "                <td>TV Show</td>" >> media.html
        echo "                <td>$seasons</td>" >> media.html
        echo "                <td>$episodes</td>" >> media.html
        echo "                <td><a href=\"$item_url\"><img src=\"$img_path\" alt=\"$show_name\" width=\"$IMAGE_SIZE\"></a></td>" >> media.html
        echo "            </tr>" >> media.html
    done <<< "$tv_shows"

    while IFS= read -r line; do
        movie_name=$(echo "$line" | cut -d ' ' -f1-$(($(echo "$line" | wc -w) - 2)))
        movie_id=$(echo "$line" | awk '{print $(NF-1)}')
        img_path="img/${movie_id}.jpg"
        item_url="${EMBY_SERVER}/item?id=${movie_id}&serverId=${SERVER_ID}"

        if [ "$LINK_TITLES" = true ]; then
            echo "            <tr>" >> media.html
            echo "                <td><a href=\"$item_url\">$movie_name</a></td>" >> media.html
        else
            echo "            <tr>" >> media.html
            echo "                <td>$movie_name</td>" >> media.html
        fi
        echo "                <td>Movie</td>" >> media.html
        echo "                <td>N/A</td>" >> media.html
        echo "                <td>N/A</td>" >> media.html
        echo "                <td><a href=\"$item_url\"><img src=\"$img_path\" alt=\"$movie_name\" width=\"$IMAGE_SIZE\"></a></td>" >> media.html
        echo "            </tr>" >> media.html
    done <<< "$movies"

    cat <<EOL >> media.html
        </tbody>
    </table>
</body>
</html>
EOL

    echo "HTML page created: media.html"
}
# Check and install dependencies
check_and_install_dependencies

# Get and display TV shows and movies
echo "Fetching TV shows from Emby..."
tv_shows=$(get_tv_shows)

echo "Fetching movies from Emby..."
movies=$(get_movies)

# Check if the response is empty or invalid
if [ -z "$tv_shows" ] && [ -z "$movies" ]; then
    echo "Failed to fetch TV shows and movies. Please check your Emby server configuration and API key."
    exit 1
fi

echo "Creating HTML page..."
create_html_page "$tv_shows" "$movies"
