// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.2 (64-bit)
// Tool Version Limit: 2023.10
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
`timescale 1ns/1ps
module userdma_control_s_axi
#(parameter
    C_S_AXI_ADDR_WIDTH = 7,
    C_S_AXI_DATA_WIDTH = 32
)(
    input  wire                          ACLK,
    input  wire                          ARESET,
    input  wire                          ACLK_EN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] AWADDR,
    input  wire                          AWVALID,
    output wire                          AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] WSTRB,
    input  wire                          WVALID,
    output wire                          WREADY,
    output wire [1:0]                    BRESP,
    output wire                          BVALID,
    input  wire                          BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] ARADDR,
    input  wire                          ARVALID,
    output wire                          ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] RDATA,
    output wire [1:0]                    RRESP,
    output wire                          RVALID,
    input  wire                          RREADY,
    output wire                          interrupt,
    input  wire [0:0]                    s2m_buf_sts,
    input  wire                          s2m_buf_sts_ap_vld,
    output wire [31:0]                   s2m_len,
    output wire [0:0]                    s2m_enb_clrsts,
    output wire [63:0]                   s2mbuf,
    input  wire [1:0]                    s2m_err,
    input  wire                          s2m_err_ap_vld,
    output wire [63:0]                   m2sbuf,
    input  wire [0:0]                    m2s_buf_sts,
    input  wire                          m2s_buf_sts_ap_vld,
    output wire [31:0]                   m2s_len,
    output wire [0:0]                    m2s_enb_clrsts,
    output wire [0:0]                    endianness,
    output wire                          ap_start,
    input  wire                          ap_done,
    input  wire                          ap_ready,
    input  wire                          ap_idle
);
//------------------------Address Info-------------------
// Protocol Used: ap_ctrl_hs
//
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read/COR)
//        bit 7  - auto_restart (Read/Write)
//        bit 9  - interrupt (Read)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0 - enable ap_done interrupt (Read/Write)
//        bit 1 - enable ap_ready interrupt (Read/Write)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0 - ap_done (Read/TOW)
//        bit 1 - ap_ready (Read/TOW)
//        others - reserved
// 0x10 : Data signal of s2m_buf_sts
//        bit 0  - s2m_buf_sts[0] (Read)
//        others - reserved
// 0x14 : Control signal of s2m_buf_sts
//        bit 0  - s2m_buf_sts_ap_vld (Read/COR)
//        others - reserved
// 0x20 : Data signal of s2m_len
//        bit 31~0 - s2m_len[31:0] (Read/Write)
// 0x24 : reserved
// 0x28 : Data signal of s2m_enb_clrsts
//        bit 0  - s2m_enb_clrsts[0] (Read/Write)
//        others - reserved
// 0x2c : reserved
// 0x30 : Data signal of s2mbuf
//        bit 31~0 - s2mbuf[31:0] (Read/Write)
// 0x34 : Data signal of s2mbuf
//        bit 31~0 - s2mbuf[63:32] (Read/Write)
// 0x38 : reserved
// 0x3c : Data signal of s2m_err
//        bit 1~0 - s2m_err[1:0] (Read)
//        others  - reserved
// 0x40 : Control signal of s2m_err
//        bit 0  - s2m_err_ap_vld (Read/COR)
//        others - reserved
// 0x4c : Data signal of m2sbuf
//        bit 31~0 - m2sbuf[31:0] (Read/Write)
// 0x50 : Data signal of m2sbuf
//        bit 31~0 - m2sbuf[63:32] (Read/Write)
// 0x54 : reserved
// 0x58 : Data signal of m2s_buf_sts
//        bit 0  - m2s_buf_sts[0] (Read)
//        others - reserved
// 0x5c : Control signal of m2s_buf_sts
//        bit 0  - m2s_buf_sts_ap_vld (Read/COR)
//        others - reserved
// 0x68 : Data signal of m2s_len
//        bit 31~0 - m2s_len[31:0] (Read/Write)
// 0x6c : reserved
// 0x70 : Data signal of m2s_enb_clrsts
//        bit 0  - m2s_enb_clrsts[0] (Read/Write)
//        others - reserved
// 0x74 : reserved
// 0x78 : Data signal of endianness
//        bit 0  - endianness[0] (Read/Write)
//        others - reserved
// 0x7c : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

//------------------------Parameter----------------------
localparam
    ADDR_AP_CTRL               = 7'h00,
    ADDR_GIE                   = 7'h04,
    ADDR_IER                   = 7'h08,
    ADDR_ISR                   = 7'h0c,
    ADDR_S2M_BUF_STS_DATA_0    = 7'h10,
    ADDR_S2M_BUF_STS_CTRL      = 7'h14,
    ADDR_S2M_LEN_DATA_0        = 7'h20,
    ADDR_S2M_LEN_CTRL          = 7'h24,
    ADDR_S2M_ENB_CLRSTS_DATA_0 = 7'h28,
    ADDR_S2M_ENB_CLRSTS_CTRL   = 7'h2c,
    ADDR_S2MBUF_DATA_0         = 7'h30,
    ADDR_S2MBUF_DATA_1         = 7'h34,
    ADDR_S2MBUF_CTRL           = 7'h38,
    ADDR_S2M_ERR_DATA_0        = 7'h3c,
    ADDR_S2M_ERR_CTRL          = 7'h40,
    ADDR_M2SBUF_DATA_0         = 7'h4c,
    ADDR_M2SBUF_DATA_1         = 7'h50,
    ADDR_M2SBUF_CTRL           = 7'h54,
    ADDR_M2S_BUF_STS_DATA_0    = 7'h58,
    ADDR_M2S_BUF_STS_CTRL      = 7'h5c,
    ADDR_M2S_LEN_DATA_0        = 7'h68,
    ADDR_M2S_LEN_CTRL          = 7'h6c,
    ADDR_M2S_ENB_CLRSTS_DATA_0 = 7'h70,
    ADDR_M2S_ENB_CLRSTS_CTRL   = 7'h74,
    ADDR_ENDIANNESS_DATA_0     = 7'h78,
    ADDR_ENDIANNESS_CTRL       = 7'h7c,
    WRIDLE                     = 2'd0,
    WRDATA                     = 2'd1,
    WRRESP                     = 2'd2,
    WRRESET                    = 2'd3,
    RDIDLE                     = 2'd0,
    RDDATA                     = 2'd1,
    RDRESET                    = 2'd2,
    ADDR_BITS                = 7;

//------------------------Local signal-------------------
    reg  [1:0]                    wstate = WRRESET;
    reg  [1:0]                    wnext;
    reg  [ADDR_BITS-1:0]          waddr;
    wire [C_S_AXI_DATA_WIDTH-1:0] wmask;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate = RDRESET;
    reg  [1:0]                    rnext;
    reg  [C_S_AXI_DATA_WIDTH-1:0] rdata;
    wire                          ar_hs;
    wire [ADDR_BITS-1:0]          raddr;
    // internal registers
    reg                           int_ap_idle;
    reg                           int_ap_ready = 1'b0;
    wire                          task_ap_ready;
    reg                           int_ap_done = 1'b0;
    wire                          task_ap_done;
    reg                           int_task_ap_done = 1'b0;
    reg                           int_ap_start = 1'b0;
    reg                           int_interrupt = 1'b0;
    reg                           int_auto_restart = 1'b0;
    reg                           auto_restart_status = 1'b0;
    wire                          auto_restart_done;
    reg                           int_gie = 1'b0;
    reg  [1:0]                    int_ier = 2'b0;
    reg  [1:0]                    int_isr = 2'b0;
    reg                           int_s2m_buf_sts_ap_vld;
    reg  [0:0]                    int_s2m_buf_sts = 'b0;
    reg  [31:0]                   int_s2m_len = 'b0;
    reg  [0:0]                    int_s2m_enb_clrsts = 'b0;
    reg  [63:0]                   int_s2mbuf = 'b0;
    reg                           int_s2m_err_ap_vld;
    reg  [1:0]                    int_s2m_err = 'b0;
    reg  [63:0]                   int_m2sbuf = 'b0;
    reg                           int_m2s_buf_sts_ap_vld;
    reg  [0:0]                    int_m2s_buf_sts = 'b0;
    reg  [31:0]                   int_m2s_len = 'b0;
    reg  [0:0]                    int_m2s_enb_clrsts = 'b0;
    reg  [0:0]                    int_endianness = 'b0;

//------------------------Instantiation------------------


//------------------------AXI write fsm------------------
assign AWREADY = (wstate == WRIDLE);
assign WREADY  = (wstate == WRDATA);
assign BRESP   = 2'b00;  // OKAY
assign BVALID  = (wstate == WRRESP);
assign wmask   = { {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
assign aw_hs   = AWVALID & AWREADY;
assign w_hs    = WVALID & WREADY;

// wstate
always @(posedge ACLK) begin
    if (ARESET)
        wstate <= WRRESET;
    else if (ACLK_EN)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (aw_hs)
            waddr <= AWADDR[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign ARREADY = (rstate == RDIDLE);
assign RDATA   = rdata;
assign RRESP   = 2'b00;  // OKAY
assign RVALID  = (rstate == RDDATA);
assign ar_hs   = ARVALID & ARREADY;
assign raddr   = ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK) begin
    if (ARESET)
        rstate <= RDRESET;
    else if (ACLK_EN)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (RREADY & RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (ar_hs) begin
            rdata <= 'b0;
            case (raddr)
                ADDR_AP_CTRL: begin
                    rdata[0] <= int_ap_start;
                    rdata[1] <= int_task_ap_done;
                    rdata[2] <= int_ap_idle;
                    rdata[3] <= int_ap_ready;
                    rdata[7] <= int_auto_restart;
                    rdata[9] <= int_interrupt;
                end
                ADDR_GIE: begin
                    rdata <= int_gie;
                end
                ADDR_IER: begin
                    rdata <= int_ier;
                end
                ADDR_ISR: begin
                    rdata <= int_isr;
                end
                ADDR_S2M_BUF_STS_DATA_0: begin
                    rdata <= int_s2m_buf_sts[0:0];
                end
                ADDR_S2M_BUF_STS_CTRL: begin
                    rdata[0] <= int_s2m_buf_sts_ap_vld;
                end
                ADDR_S2M_LEN_DATA_0: begin
                    rdata <= int_s2m_len[31:0];
                end
                ADDR_S2M_ENB_CLRSTS_DATA_0: begin
                    rdata <= int_s2m_enb_clrsts[0:0];
                end
                ADDR_S2MBUF_DATA_0: begin
                    rdata <= int_s2mbuf[31:0];
                end
                ADDR_S2MBUF_DATA_1: begin
                    rdata <= int_s2mbuf[63:32];
                end
                ADDR_S2M_ERR_DATA_0: begin
                    rdata <= int_s2m_err[1:0];
                end
                ADDR_S2M_ERR_CTRL: begin
                    rdata[0] <= int_s2m_err_ap_vld;
                end
                ADDR_M2SBUF_DATA_0: begin
                    rdata <= int_m2sbuf[31:0];
                end
                ADDR_M2SBUF_DATA_1: begin
                    rdata <= int_m2sbuf[63:32];
                end
                ADDR_M2S_BUF_STS_DATA_0: begin
                    rdata <= int_m2s_buf_sts[0:0];
                end
                ADDR_M2S_BUF_STS_CTRL: begin
                    rdata[0] <= int_m2s_buf_sts_ap_vld;
                end
                ADDR_M2S_LEN_DATA_0: begin
                    rdata <= int_m2s_len[31:0];
                end
                ADDR_M2S_ENB_CLRSTS_DATA_0: begin
                    rdata <= int_m2s_enb_clrsts[0:0];
                end
                ADDR_ENDIANNESS_DATA_0: begin
                    rdata <= int_endianness[0:0];
                end
            endcase
        end
    end
end


//------------------------Register logic-----------------
assign interrupt         = int_interrupt;
assign ap_start          = int_ap_start;
assign task_ap_done      = (ap_done && !auto_restart_status) || auto_restart_done;
assign task_ap_ready     = ap_ready && !int_auto_restart;
assign auto_restart_done = auto_restart_status && (ap_idle && !int_ap_idle);
assign s2m_len           = int_s2m_len;
assign s2m_enb_clrsts    = int_s2m_enb_clrsts;
assign s2mbuf            = int_s2mbuf;
assign m2sbuf            = int_m2sbuf;
assign m2s_len           = int_m2s_len;
assign m2s_enb_clrsts    = int_m2s_enb_clrsts;
assign endianness        = int_endianness;
// int_interrupt
always @(posedge ACLK) begin
    if (ARESET)
        int_interrupt <= 1'b0;
    else if (ACLK_EN) begin
        if (int_gie && (|int_isr))
            int_interrupt <= 1'b1;
        else
            int_interrupt <= 1'b0;
    end
end

// int_ap_start
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_start <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0] && WDATA[0])
            int_ap_start <= 1'b1;
        else if (ap_ready)
            int_ap_start <= int_auto_restart; // clear on handshake/auto restart
    end
end

// int_ap_done
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_done <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_done <= ap_done;
    end
end

// int_task_ap_done
always @(posedge ACLK) begin
    if (ARESET)
        int_task_ap_done <= 1'b0;
    else if (ACLK_EN) begin
        if (task_ap_done)
            int_task_ap_done <= 1'b1;
        else if (ar_hs && raddr == ADDR_AP_CTRL)
            int_task_ap_done <= 1'b0; // clear on read
    end
end

// int_ap_idle
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_idle <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_idle <= ap_idle;
    end
end

// int_ap_ready
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_ready <= 1'b0;
    else if (ACLK_EN) begin
        if (task_ap_ready)
            int_ap_ready <= 1'b1;
        else if (ar_hs && raddr == ADDR_AP_CTRL)
            int_ap_ready <= 1'b0;
    end
end

// int_auto_restart
always @(posedge ACLK) begin
    if (ARESET)
        int_auto_restart <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0])
            int_auto_restart <=  WDATA[7];
    end
end

// auto_restart_status
always @(posedge ACLK) begin
    if (ARESET)
        auto_restart_status <= 1'b0;
    else if (ACLK_EN) begin
        if (int_auto_restart)
            auto_restart_status <= 1'b1;
        else if (ap_idle)
            auto_restart_status <= 1'b0;
    end
end

// int_gie
always @(posedge ACLK) begin
    if (ARESET)
        int_gie <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_GIE && WSTRB[0])
            int_gie <= WDATA[0];
    end
end

// int_ier
always @(posedge ACLK) begin
    if (ARESET)
        int_ier <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_IER && WSTRB[0])
            int_ier <= WDATA[1:0];
    end
end

// int_isr[0]
always @(posedge ACLK) begin
    if (ARESET)
        int_isr[0] <= 1'b0;
    else if (ACLK_EN) begin
        if (int_ier[0] & ap_done)
            int_isr[0] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
            int_isr[0] <= int_isr[0] ^ WDATA[0]; // toggle on write
    end
end

// int_isr[1]
always @(posedge ACLK) begin
    if (ARESET)
        int_isr[1] <= 1'b0;
    else if (ACLK_EN) begin
        if (int_ier[1] & ap_ready)
            int_isr[1] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
            int_isr[1] <= int_isr[1] ^ WDATA[1]; // toggle on write
    end
end

// int_s2m_buf_sts
always @(posedge ACLK) begin
    if (ARESET)
        int_s2m_buf_sts <= 0;
    else if (ACLK_EN) begin
        if (s2m_buf_sts_ap_vld)
            int_s2m_buf_sts <= s2m_buf_sts;
    end
end

// int_s2m_buf_sts_ap_vld
always @(posedge ACLK) begin
    if (ARESET)
        int_s2m_buf_sts_ap_vld <= 1'b0;
    else if (ACLK_EN) begin
        if (s2m_buf_sts_ap_vld)
            int_s2m_buf_sts_ap_vld <= 1'b1;
        else if (ar_hs && raddr == ADDR_S2M_BUF_STS_CTRL)
            int_s2m_buf_sts_ap_vld <= 1'b0; // clear on read
    end
end

// int_s2m_len[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_s2m_len[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_S2M_LEN_DATA_0)
            int_s2m_len[31:0] <= (WDATA[31:0] & wmask) | (int_s2m_len[31:0] & ~wmask);
    end
end

// int_s2m_enb_clrsts[0:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_s2m_enb_clrsts[0:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_S2M_ENB_CLRSTS_DATA_0)
            int_s2m_enb_clrsts[0:0] <= (WDATA[31:0] & wmask) | (int_s2m_enb_clrsts[0:0] & ~wmask);
    end
end

// int_s2mbuf[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_s2mbuf[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_S2MBUF_DATA_0)
            int_s2mbuf[31:0] <= (WDATA[31:0] & wmask) | (int_s2mbuf[31:0] & ~wmask);
    end
end

// int_s2mbuf[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_s2mbuf[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_S2MBUF_DATA_1)
            int_s2mbuf[63:32] <= (WDATA[31:0] & wmask) | (int_s2mbuf[63:32] & ~wmask);
    end
end

// int_s2m_err
always @(posedge ACLK) begin
    if (ARESET)
        int_s2m_err <= 0;
    else if (ACLK_EN) begin
        if (s2m_err_ap_vld)
            int_s2m_err <= s2m_err;
    end
end

// int_s2m_err_ap_vld
always @(posedge ACLK) begin
    if (ARESET)
        int_s2m_err_ap_vld <= 1'b0;
    else if (ACLK_EN) begin
        if (s2m_err_ap_vld)
            int_s2m_err_ap_vld <= 1'b1;
        else if (ar_hs && raddr == ADDR_S2M_ERR_CTRL)
            int_s2m_err_ap_vld <= 1'b0; // clear on read
    end
end

// int_m2sbuf[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_m2sbuf[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_M2SBUF_DATA_0)
            int_m2sbuf[31:0] <= (WDATA[31:0] & wmask) | (int_m2sbuf[31:0] & ~wmask);
    end
end

// int_m2sbuf[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_m2sbuf[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_M2SBUF_DATA_1)
            int_m2sbuf[63:32] <= (WDATA[31:0] & wmask) | (int_m2sbuf[63:32] & ~wmask);
    end
end

// int_m2s_buf_sts
always @(posedge ACLK) begin
    if (ARESET)
        int_m2s_buf_sts <= 0;
    else if (ACLK_EN) begin
        if (m2s_buf_sts_ap_vld)
            int_m2s_buf_sts <= m2s_buf_sts;
    end
end

// int_m2s_buf_sts_ap_vld
always @(posedge ACLK) begin
    if (ARESET)
        int_m2s_buf_sts_ap_vld <= 1'b0;
    else if (ACLK_EN) begin
        if (m2s_buf_sts_ap_vld)
            int_m2s_buf_sts_ap_vld <= 1'b1;
        else if (ar_hs && raddr == ADDR_M2S_BUF_STS_CTRL)
            int_m2s_buf_sts_ap_vld <= 1'b0; // clear on read
    end
end

// int_m2s_len[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_m2s_len[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_M2S_LEN_DATA_0)
            int_m2s_len[31:0] <= (WDATA[31:0] & wmask) | (int_m2s_len[31:0] & ~wmask);
    end
end

// int_m2s_enb_clrsts[0:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_m2s_enb_clrsts[0:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_M2S_ENB_CLRSTS_DATA_0)
            int_m2s_enb_clrsts[0:0] <= (WDATA[31:0] & wmask) | (int_m2s_enb_clrsts[0:0] & ~wmask);
    end
end

// int_endianness[0:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_endianness[0:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_ENDIANNESS_DATA_0)
            int_endianness[0:0] <= (WDATA[31:0] & wmask) | (int_endianness[0:0] & ~wmask);
    end
end

//synthesis translate_off
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (int_gie & ~int_isr[0] & int_ier[0] & ap_done)
            $display ("// Interrupt Monitor : interrupt for ap_done detected @ \"%0t\"", $time);
        if (int_gie & ~int_isr[1] & int_ier[1] & ap_ready)
            $display ("// Interrupt Monitor : interrupt for ap_ready detected @ \"%0t\"", $time);
    end
end
//synthesis translate_on

//------------------------Memory logic-------------------

endmodule
