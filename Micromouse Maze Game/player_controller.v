module player_controller(
    input clk,
    input load,
    input reset,
    input [624:0] maze,
    input [3:0] input_direction,
    output [7:0] player_x_out,
    output [7:0] player_y_out
);

    // Direction 
    localparam UP    = 4'b0001;
    localparam RIGHT = 4'b0010;
    localparam DOWN  = 4'b0100;
    localparam LEFT  = 4'b1000;

    // Maze
    localparam WALL = 1'b0;
    localparam PATH = 1'b1;

    // States
    localparam IDLE        = 3'b001;
    localparam BTN_PRESS   = 3'b010;
    localparam MOVE_PLAYER = 3'b011;
    localparam BTN_RELEASE = 3'b100;

    reg initialized;
    reg [624:0] maze_reg;
    reg [2:0] state, next_state;
    reg [31:0] debounce_counter;
    reg [7:0] player_x_current, player_y_current;
    reg [3:0] direction_reg;

    // Outputs
    assign player_x_out = player_x_current;
    assign player_y_out = player_y_current;

    // Sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            initialized <= 0;
            player_x_current <= 1;
            player_y_current <= 1;
            debounce_counter <= 6'b100000;
            state <= IDLE;
            direction_reg <= 0;
        end 
        else if (load && !initialized) begin
            player_x_current <= 1;
            player_y_current <= 1;
            maze_reg <= maze;
            initialized <= 1;
            debounce_counter <= 6'b100000;
            state <= IDLE;
            direction_reg <= 0;
        end
        else if (initialized) begin
            state <= next_state;

            
            if (state == IDLE && input_direction != 0)
                direction_reg <= input_direction;

            if (state == BTN_PRESS && debounce_counter > 0)
                debounce_counter <= debounce_counter - 1;
            else if (state == MOVE_PLAYER)
                debounce_counter <= 6'b100000;

            if (state == MOVE_PLAYER) begin
                case (direction_reg)
                    UP: if (player_y_current > 1 && maze_reg[(player_y_current - 1)*25 + player_x_current] == PATH)
                            player_y_current <= player_y_current - 1;
                    DOWN: if (player_y_current < 24 && maze_reg[(player_y_current + 1)*25 + player_x_current] == PATH)
                            player_y_current <= player_y_current + 1;
                    LEFT: if (player_x_current > 1 && maze_reg[player_y_current*25 + (player_x_current - 1)] == PATH)
                            player_x_current <= player_x_current - 1;
                    RIGHT: if (player_x_current < 24 && maze_reg[player_y_current*25 + (player_x_current + 1)] == PATH)
                            player_x_current <= player_x_current + 1;
                endcase
            end
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (input_direction != 0)
                    next_state = BTN_PRESS;
            end

            BTN_PRESS: begin
                if (input_direction == 0)
                    next_state = IDLE;
                else if (debounce_counter == 0)
                    next_state = MOVE_PLAYER;
            end

            MOVE_PLAYER: begin
                next_state = BTN_RELEASE;
            end

            BTN_RELEASE: begin
                if (input_direction == 0)
                    next_state = IDLE;
            end
        endcase
    end

endmodule

