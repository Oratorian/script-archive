let initialUsername = sessionStorage.getItem('username') || '';
let initialPasswordHash = sessionStorage.getItem('passwordHash') || '';
let pendingDeletionMac = null;

$(document).ready(function() {
    console.log("Document ready, checking initial credentials");
    $('.modal').modal();

    if (initialUsername && initialPasswordHash) {
        console.log("Initial credentials found, attempting authentication");
        authenticate(initialUsername, initialPasswordHash, function(success) {
            if (success) {
                console.log("Initial authentication successful");
                load_pcs();
            } else {
                console.log("Initial authentication failed");
                $('#auth-modal').modal('open');
            }
        });
    } else {
        console.log("No initial credentials found, opening auth modal");
        $('#auth-modal').modal('open');
    }

    $('#auth-submit').click(function() {
        handleAuthSubmit();
    });

    $('#auth-username, #auth-password').on('keypress', function(e) {
        if (e.which === 13) {  // Enter key pressed
            handleAuthSubmit();
        }
    });

    $('#logout-button').click(function() {
        console.log("Logout button clicked, clearing credentials");
        sessionStorage.removeItem('username');
        sessionStorage.removeItem('passwordHash');
        initialUsername = '';
        initialPasswordHash = '';
        $('#auth-modal').modal('open');
    });
});

function hashPassword(password) {
    return CryptoJS.SHA256(password).toString();
}

function authenticate(username, passwordHash, callback) {
    console.log("Authenticating with username:", username);
    $.ajax({
        type: 'GET',
        url: '/api/wol_server.py',
        headers: {
            'Authorization': 'Basic ' + btoa(username + ':' + passwordHash)
        },
        success: function(data) {
            if (data.success) {
                console.log("Authentication success for username:", username);
                callback(true);
            } else {
                console.log("Authentication failed for username:", username);
                M.toast({html: data.message});
                callback(false);
            }
        },
        error: function(xhr, status, error) {
            console.log("Unexpected error for username:", username, "status:", status, "error:", error);
            if (xhr.responseText) {
                try {
                    const response = JSON.parse(xhr.responseText);
                    console.log("Response from server:", response);
                    M.toast({html: response.message});
                } catch (e) {
                    console.log("Failed to parse server response as JSON:", xhr.responseText);
                }
            } else {
                console.log("Empty response from server");
            }
            callback(false);
        },
        dataType: 'json'
    });
}

function handleAuthSubmit() {
    const username = $('#auth-username').val();
    const password = $('#auth-password').val();
    if (username && password) {
        console.log("Submitting authentication for username:", username);
        const passwordHash = hashPassword(password);
        authenticate(username, passwordHash, function(success) {
            if (success) {
                console.log("Authentication successful, storing credentials");
                initialUsername = username;
                initialPasswordHash = passwordHash;
                sessionStorage.setItem('username', username);
                sessionStorage.setItem('passwordHash', passwordHash);
                $('#auth-modal').modal('close');
                if (pendingDeletionMac) {
                    delete_pc(pendingDeletionMac, true);
                    pendingDeletionMac = null;
                } else {
                    load_pcs();
                }
            } else {
                console.log("Authentication failed for username:", username);
                M.toast({html: 'Authentication failed. Please try again.'});
            }
        });
    } else {
        console.log("Username and password required");
        M.toast({html: 'Username and password are required.'});
    }
}
