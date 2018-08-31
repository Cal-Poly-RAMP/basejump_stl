/**
 *  mesh_top_cache.v
 */

`include "bsg_manycore_packet.vh"
`include "bsg_cache_dma_pkt.vh"

module mesh_top_cache
  import bsg_cache_pkg::*;
  #(parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter dram_data_width_p="inv"
    ,parameter link_addr_width_lp=32-1-x_cord_width_p-y_cord_width_p // remote addr width
    ,parameter sets_p="inv"
    ,parameter mem_size_p="inv"
    ,parameter packet_width_lp=`bsg_manycore_packet_width(link_addr_width_lp,data_width_p,x_cord_width_p,y_cord_width_p)
    ,parameter return_packet_width_lp=`bsg_manycore_return_packet_width(x_cord_width_p,y_cord_width_p,data_width_p)
    ,parameter link_sif_width_lp=`bsg_manycore_link_sif_width(link_addr_width_lp,data_width_p,x_cord_width_p,y_cord_width_p)
    ,parameter cache_addr_width_lp=link_addr_width_lp+`BSG_SAFE_CLOG2(data_width_p>>3)
)
(
  input clock_i
  ,input reset_i

  ,bsg_dram_ctrl_if.master dram_ctrl_if

  ,output logic finish_o
);

  localparam nodes_lp = 2;

  logic [nodes_lp-1:0][bsg_noc_pkg::S:bsg_noc_pkg::W][link_sif_width_lp-1:0] router_link_sif_li, router_link_sif_lo;
  logic [nodes_lp-1:0][link_sif_width_lp-1:0] proc_link_sif_li, proc_link_sif_lo;

  genvar i, j;
  for (i = 0; i < nodes_lp; i++) begin
    bsg_manycore_mesh_node #(
      .stub_p(4'b0)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.data_width_p(data_width_p)
      ,.addr_width_p(link_addr_width_lp)  
    ) mesh_node (
      .clk_i(clock_i)
      ,.reset_i(reset_i)
      ,.links_sif_i(router_link_sif_li[i])
      ,.links_sif_o(router_link_sif_lo[i])
      ,.proc_link_sif_i(proc_link_sif_lo[i])
      ,.proc_link_sif_o(proc_link_sif_li[i])
      ,.my_x_i(x_cord_width_p'(i))
      ,.my_y_i(y_cord_width_p'(0))
    );
  end 

  assign router_link_sif_li[0][bsg_noc_pkg::E] = router_link_sif_lo[1][bsg_noc_pkg::W];
  assign router_link_sif_li[1][bsg_noc_pkg::W] = router_link_sif_lo[0][bsg_noc_pkg::E];

  mesh_master_cache #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(link_addr_width_lp)
    ,.sets_p(sets_p)
    ,.ways_p(2)
    ,.mem_size_p(mem_size_p)
  ) master (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.link_sif_i(proc_link_sif_li[0])
    ,.link_sif_o(proc_link_sif_lo[0])
    
    ,.my_x_i(x_cord_width_p'(0))
    ,.my_y_i(y_cord_width_p'(0))
  
    ,.finish_o(finish_o)
  );

  // tieoff
  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node00_w_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[0][bsg_noc_pkg::W])
    ,.link_sif_o(router_link_sif_li[0][bsg_noc_pkg::W])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node00_n_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[0][bsg_noc_pkg::N])
    ,.link_sif_o(router_link_sif_li[0][bsg_noc_pkg::N])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node11_n_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[1][bsg_noc_pkg::N])
    ,.link_sif_o(router_link_sif_li[1][bsg_noc_pkg::N])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node11_e_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[1][bsg_noc_pkg::E])
    ,.link_sif_o(router_link_sif_li[1][bsg_noc_pkg::E])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node11_s_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[1][bsg_noc_pkg::S])
    ,.link_sif_o(router_link_sif_li[1][bsg_noc_pkg::S])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node01_p_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(proc_link_sif_li[1])
    ,.link_sif_o(proc_link_sif_lo[1])
  );

  // cache-side signals
  //
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s cache_packet;
  logic link_to_cache_v_lo;
  logic link_to_cache_yumi_lo;
  logic cache_ready_lo;
  logic [data_width_p-1:0] cache_data_lo;
  logic cache_v_lo;
  logic cache_v_v_we_lo;

  // link_to_cache
  //
  bsg_manycore_link_to_cache #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.tag_mem_boundary_p(2**25)
  ) link_to_cache (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
    ,.my_x_i((x_cord_width_p)'(0))
    ,.my_y_i((y_cord_width_p)'(1))
    ,.link_sif_i(router_link_sif_lo[0][bsg_noc_pkg::S])
    ,.link_sif_o(router_link_sif_li[0][bsg_noc_pkg::S])

    ,.packet_o(cache_packet)
    ,.v_o(link_to_cache_v_lo)
    ,.ready_i(cache_ready_lo)

    ,.data_i(cache_data_lo)
    ,.v_i(cache_v_lo)
    ,.yumi_o(link_to_cache_yumi_lo)

    ,.v_v_we_i(cache_v_v_we_lo)
  ); 
  
  // cache
  //
  `declare_bsg_cache_dma_pkt_s(cache_addr_width_lp);
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;

  logic dma_data_ready_lo;
  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li;
  
  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  bsg_cache #(
    .data_width_p(32)
    ,.addr_width_p(cache_addr_width_lp)
    ,.block_size_in_words_p(8)
    ,.sets_p(sets_p)
  ) cache (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.packet_i(cache_packet)
    ,.v_i(link_to_cache_v_lo)
    ,.ready_o(cache_ready_lo)

    ,.data_o(cache_data_lo)
    ,.v_o(cache_v_lo)
    ,.yumi_i(link_to_cache_yumi_lo)

    ,.v_v_we_o(cache_v_v_we_lo)

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
  );
  

  // cache to dram_ctrl
  //
  bsg_cache_to_dram_ctrl #(
    .addr_width_p(cache_addr_width_lp)
    ,.block_size_in_words_p(8)
    ,.cache_word_width_p(data_width_p)
    ,.burst_len_p(1)
    ,.burst_width_p(dram_data_width_p)
  ) cache_to_dram_ctrl (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)

    ,.dram_ctrl_if(dram_ctrl_if)
  );
  
endmodule