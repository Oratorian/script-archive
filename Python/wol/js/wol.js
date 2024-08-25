function load_pcs() {
    $.ajax({
        type: 'GET',
        url: '/api/load',  // Ensure this URL matches the Flask route
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash')),
        },
        success: function(data) {
            if (data.success) {
                console.log("PC list loaded successfully");
                $('#pcs-list').html(data.pcs_list.map(pc => `
                    <li class="collection-item">
                        ${pc.hostname} (${pc.mac})
                        <a href="#!" class="secondary-content" onclick="shutdown_pc('${pc.ip}')"><i class="material-icons">power_off</i></a>
                        <a href="#!" class="secondary-content" onclick="wake_pc('${pc.mac}')"><i class="material-icons">power</i></a>
                        <a href="#!" class="secondary-content" onclick="delete_pc('${pc.mac}')"><i class="material-icons">delete</i></a>
                    </li>
                `).join(''));
            } else {
                console.log("Failed to load PC list");
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error loading PC list", "status:", status, "error:", error);
            M.toast({html: 'Failed to load PC list. Please try again.'});
        },
        dataType: 'json'
    });
}

$(document).ready(function() {
    $('#logout-button').click(function() {
        $.ajax({
            type: 'GET',
            url: '/logout',  // This should match your Flask logout route
            success: function() {
                // Redirect to the login page or display a message
                window.location.href = '/login';
            },
            error: function(xhr, status, error) {
                console.log("Logout failed", "status:", status, "error:", error);
                M.toast({html: 'Failed to log out. Please try again.'});
            }
        });
    });
});

function wake_pc(mac) {
    $.ajax({
        type: 'GET',
        url: '/api/wake?mac=' + mac,  // Adjusted URL to match Flask route
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash'))
        },
        success: function(data) {
            if (data.success) {
                console.log("Wake-up signal sent successfully to", mac);
                M.toast({html: data.message});
            } else {
                console.log("Failed to send wake-up signal to", mac);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error sending wake-up signal", "status:", status, "error:", error);
            M.toast({html: 'Failed to send wake-up signal. Please try again.'});
        },
        dataType: 'json'
    });
}

function delete_pc(mac) {
    $.ajax({
        type: 'GET',
        url: '/api/delete?mac=' + mac,  // Adjusted URL to match Flask route
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash'))
        },
        success: function(data) {
            if (data.success) {
                console.log("PC deleted successfully", mac);
                load_pcs(); // Reload the PC list after deletion
                M.toast({html: data.message});
            } else {
                console.log("Failed to delete PC", mac);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error deleting PC", "status:", status, "error:", error);
            M.toast({html: 'Failed to delete PC. Please try again.'});
        },
        dataType: 'json'
    });
}

function shutdown_pc(ip) {
    const username = prompt("Enter your username for shutdown:");
    const password = prompt("Enter your password for shutdown:");
    if (!password) {
        M.toast({html: 'Password is required for shutdown.'});
        return;
    }
    if (!username) {
        M.toast({html: 'Username is required for shutdown.'});
        return;
    }

    $.ajax({
        type: 'POST',
        url: '/api/shutdown',
        contentType: 'application/json',
        data: JSON.stringify({
            'username' : username,
            'pc_ip': ip,
            'password': password
        }),
        success: function(data) {
            if (data.success) {
                console.log("Shutdown command sent successfully to", ip);
                M.toast({html: data.message});
            } else {
                console.log("Failed to send shutdown command to", ip);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error sending shutdown command", "status:", status, "error:", error);
            M.toast({html: 'Failed to send shutdown command. Please try again.'});
        },
        dataType: 'json'
    });
}

function load_users() {
    $.ajax({
        type: 'GET',
        url: '/api/users',
        success: function(data) {
            if (data.success) {
                console.log("Users loaded successfully.");

                // Clear the current list
                $('#user-list').empty();

                // Iterate over the keys of the object
                Object.keys(data.users).forEach(function(username) {
                    const user = data.users[username];

                    // Create an element for each user
                    const userItem = `
                    <li class="collection-item">
                        <div class="user-item">
                            <span class="username-label">Username: </span>
                            <span class="username">${user.username}</span>
                            <span class="permission-label">Permission: </span>
                            <div class="input-field inline">
                            <select class="browser-default permission-select" data-username="${user.username}">
                                <option value="admin" ${user.permission === 'admin' ? 'selected' : ''}>Admin</option>
                                <option value="user" ${user.permission === 'user' ? 'selected' : ''}>User</option>
                            </select>
                        </div>
                            <button class="btn-small green right change-password-btn" data-username="${user.username}">
                                Change Password
                            </button>
                            <button class="btn-small blue right change-permission-btn" data-username="${user.username}">
                                Change Permission
                            </button>
                            <button class="btn-small red right delete-user-btn" data-username="${user.username}">
                                Delete
                            </button>
                        </div>
                    </li>
                    `;

                    // Append it to the list
                    $('#user-list').append(userItem);
                });

                // Add event listeners for the buttons (delete, change permission, etc.)
                $('.delete-user-btn').on('click', function() {
                    const username = $(this).data('username');
                    deleteUser(username);
                });

                $('.change-permission-btn').on('click', function() {
                    const username = $(this).data('username');
                    const newPermission = $(`select[data-username='${username}']`).val(); // Get the selected permission
                    changeUserPermission(username, newPermission);
                });

                $('.change-password-btn').on('click', function() {
                    const username = $(this).data('username');
                    changeUserPassword(username);
                });
            } else {
                console.log("Failed to load users:", data.message);  // Debugging: Log failure message
                M.toast({html: 'Failed to load users.'});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error fetching users", "status:", status, "error:", error);  // Debugging: Log error details
            M.toast({html: 'Failed to load users. Please try again.'});
        },
        dataType: 'json'
    });
}

function changeUserPassword(username) {
    const newPassword = prompt("Enter new password for " + username + ":");

    if (newPassword) {
        $.ajax({
            type: 'POST',
            url: '/api/change_password',  // This endpoint should be created in your Flask app
            contentType: 'application/json',
            data: JSON.stringify({ username: username, password: newPassword }),
            success: function(response) {
                if (response.success) {
                    M.toast({html: 'Password updated successfully'});
                } else {
                    M.toast({html: response.message});
                }
            },
            error: function(xhr, status, error) {
                console.error("Error changing password", "status:", status, "error:", error);
                M.toast({html: 'Failed to change password. Please try again.'});
            }
        });
    }
}

function changeUserPermission(username, newPermission) {
    if (newPermission) {
        $.ajax({
            type: 'POST',
            url: '/api/change_permission',
            contentType: 'application/json',
            data: JSON.stringify({ username: username, permission: newPermission }),
            success: function(response) {
                if (response.success) {
                    M.toast({html: response.message});
                    load_users();  // Reload the users to reflect changes
                } else {
                    M.toast({html: response.message});
                }
            },
            error: function(xhr, status, error) {
                console.error("Error changing user permission", "status:", status, "error:", error);
                M.toast({html: 'Failed to change user permission. Please try again.'});
            }
        });
    }
}

function deleteUser(username) {
    if (confirm(`Are you sure you want to delete user ${username}?`)) {
        $.ajax({
            type: 'POST',
            url: '/api/delete_user',
            contentType: 'application/json',
            data: JSON.stringify({username: username}),
            success: function(data) {
                if (data.success) {
                    M.toast({html: 'User deleted successfully'});
                    load_users();  // Reload the user list after deletion
                } else {
                    M.toast({html: data.message});
                }
            },
            error: function(xhr, status, error) {
                console.log("Error deleting user", "status:", status, "error:", error);
                M.toast({html: 'Failed to delete user. Please try again.'});
            },
            dataType: 'json'
        });
    }
}

$('#add-pc-form').submit(function(event) {
    event.preventDefault();
    const mac = $('#mac').val();
    const ip = $('#ip').val();
    const hostname = $('#hostname').val();

    const dataToSend = JSON.stringify({
        'mac': mac,
        'ip': ip,
        'hostname': hostname
    });

    console.log("Data being sent:", dataToSend);  // Debugging log

    $.ajax({
        type: 'POST',
        url: '/api/add',
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash')),
            'Content-Type': 'application/json'
        },
        data: dataToSend,  // Send JSON string data
        success: function(data) {
            if (data.success) {
                console.log("PC added successfully", data);
                load_pcs(); // Reload the PC list after adding
                M.toast({html: data.message});
                $('#mac').val('');
                $('#ip').val('');
                $('#hostname').val('');
            } else {
                console.log("Failed to add PC", data);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error adding PC", "status:", status, "error:", error);
            M.toast({html: 'Failed to add PC. Please try again.'});
        },
        dataType: 'json'
    });
});

$('#create-user-form').submit(function(event) {
    event.preventDefault();
    const username = $('#username').val();
    const password = $('#password').val();
    const permission = $('#permission').val();

    const dataToSend = JSON.stringify({
        'username': username,
        'password': password,
        'permission': permission
    });

    $.ajax({
        url: '/create_user',
        type: 'POST',  // Make sure this is POST
        contentType: 'application/json',
        data: dataToSend,
        success: function(data) {
            if (data.success) {
                console.log("User added successfully", data);
                load_users();
                M.toast({html: data.message});
                $('#username').val('');
                $('#password').val('');
            } else {
                console.log("Failed to add Userr", data);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error adding User", "status:", status, "error:", error);
            M.toast({html: 'Failed to add User. Please try again.'});
        },
        dataType: 'json'
    });
});

document.addEventListener('DOMContentLoaded', function() {
    var elems = document.querySelectorAll('select');
    var instances = M.FormSelect.init(elems);
});

// Call load_pcs() when the page loads or user logs in
$(document).ready(function() {
    load_pcs();
    $('.tabs').tabs();
    $('select').formSelect();  // Initialize the select elements

    // Load users when the Manage Users tab is activated
    $('.tabs').tabs({
        onShow: function(tab) {
            var $tab = $(tab); // Ensure tab is wrapped in jQuery object
            if ($tab.attr('id') === 'manage-users') {
                load_users();
            }
        }
    });
});